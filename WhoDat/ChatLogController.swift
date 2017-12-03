//
//  ChatLogController.swift
//  WhoDat
//
//  Created by Sathyavarathan Sivabalasingam on 10/15/17.
//  Copyright © 2017 LTAC. All rights reserved.
//

import UIKit
import Firebase
import GoogleMobileAds

class ChatLogController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, GADInterstitialDelegate {
    
    var interstitial: GADInterstitial!
    
    lazy var inputTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Enter message..."
        textField.delegate = self
        return textField
    }()
    
    var account: Account? {
        didSet {
            self.setNavBar(account: account!)
            if account?.representedUserId == nil {
                findARepresentation()
            }
        }
    }
    
    let cellId = "cellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        collectionView?.alwaysBounceVertical = true
        collectionView?.backgroundColor = UIColor.white
        collectionView?.register(MessageCell.self, forCellWithReuseIdentifier: cellId)
        collectionView?.keyboardDismissMode = .interactive

        messages = [Message]()
        //setupKeyboardObservers()
        setGuessButton()
        //observeUserMessages()
        observeAlert()
        interstitial = createAndLoadInterstitial()
    }
    
    func createAndLoadInterstitial() -> GADInterstitial {
        interstitial = GADInterstitial(adUnitID: "ca-app-pub-2292982215135045/9885798429")
        interstitial.delegate = self
        let request = GADRequest()
        request.testDevices = [kGADSimulatorID]
        interstitial.load(request)
        return interstitial
    }
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        interstitial = createAndLoadInterstitial()
        handleSee()
    }
    
    @objc func showAds() {
        if interstitial.isReady {
            interstitial.present(fromRootViewController: self)
        } else {
            handleSee()
        }
    }
    func observeAlert() {
        print("setup alert observe")
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let ref = Database.database().reference().child("connections").child(uid).child(account!.id!)
        ref.observe(.childRemoved, with: {(snapshot) in
            self.showAlert()
        })
    }
    
    var guessButton: UIBarButtonItem?
    var seeButton: UIBarButtonItem?
    
    func setGuessButton() {
        self.guessButton = UIBarButtonItem(title: "Who?", style: .plain, target: self, action: #selector(handleGuess))
        self.guessButton?.tintColor = UIColor.red
        navigationItem.rightBarButtonItem = guessButton
        
        let infoButton = UIButton(type: .infoLight)
        infoButton.addTarget(self, action: #selector(showAds), for: .touchUpInside)
        self.seeButton = UIBarButtonItem(customView: infoButton)
        setupAttention()
    }
    
    private func setupAttention() {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        let foundIndicator = navigationItem.titleView?.viewWithTag(111)
        let beenCaughtIndicator = navigationItem.titleView?.viewWithTag(222)
        
        let refCaught = Database.database().reference().child("users-caught").child(uid).queryOrderedByKey()
            .queryEqual(toValue: account!.id!)
        refCaught.observe(.value, with: {(snapshot) in
            if let dictionary = snapshot.value as? [String: Int] {
                let value = Array(dictionary)[0].value
                if value == 1 {
                    foundIndicator?.isHidden = false
                    self.navigationItem.rightBarButtonItem = self.seeButton
                } else if value == 0 {
                    self.navigationItem.rightBarButtonItem = nil
                    foundIndicator?.isHidden = true
                }
                
            } else {
                self.navigationItem.rightBarButtonItem = self.guessButton
                foundIndicator?.isHidden = true
            }
        })
        
        self.account?.beenCaught = false
        
        let refBeenCaught = Database.database().reference().child("users-been-caught").child(uid).queryOrderedByKey().queryEqual(toValue: account!.id!)
        refBeenCaught.observe(.value, with: {(snapshot) in
            if let _ = snapshot.value as? [String: Int] {
                beenCaughtIndicator?.isHidden = false
                self.account?.beenCaught = true
            } else {
                self.account?.beenCaught = false
                beenCaughtIndicator?.isHidden = true
            }
            
        })
        
    }
    
    func showAlert() {
        let alert = UIAlertController(title: "Well Done!", message: "You both have caught each other.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: {(_) in
            self.navigationController?.popViewController(animated: true)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        observeUserMessages()
        setupKeyboardObservers()
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let refUpdate = Database.database().reference().child("last-user-message-read").child(uid)
        refUpdate.updateChildValues([account!.id!: 0])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setBadgeCount()
    }
    
    func setBadgeCount() {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let ref = Database.database().reference().child("last-user-message-read").child(uid)
        ref.observeSingleEvent(of: .value, with: {(snapshot) in
            if let dictionary = snapshot.value as? [String: Int] {
                var total = 0 ;
                for item in dictionary {
                    total += item.value
                }
                DispatchQueue.main.async {
                    UIApplication.shared.applicationIconBadgeNumber = total
                }
            }
        })
    }
    
    @objc func handleSee() {
        if let representedUser = LocalUserRepository.shared().loadUserFromCache(uid: account!.representedUserId!) {
            showUserProfile(account: representedUser)
        } else {
            Database.database().reference().child("users").child(account!.representedUserId!).observeSingleEvent(of: .value, with: {(snapshot) in
                if let dictionary = snapshot.value as? [String: AnyObject] {
                    let account = Account()
                    account.id = snapshot.key
                    account.setValuesForKeys(dictionary)
                    LocalUserRepository.shared().setObject(account)
                    
                    self.showUserProfile(account: account)
                }
            })
        }
    }
    
    func showUserProfile(account: Account) {
        let alert = UIAlertController(title: "You got 'em!", message: "You are chatting with:", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: {(_) in }))
        let heightConstraint = NSLayoutConstraint(item: alert.view, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: self.view.frame.height * 0.35)
        alert.view.addConstraint(heightConstraint)
        
        let profileImageView = UIImageView()
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = (alert.view.frame.height * 4/36) * 1/2
        profileImageView.clipsToBounds = true
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        
        if let profileImageUrl = account.profileImageUrl {
            profileImageView.loadImagesFromCache(urlString: profileImageUrl)
        } else {
            profileImageView.image = UIImage(named: "profilepic")
        }
        
        alert.view.addSubview(profileImageView)
        profileImageView.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: alert.view.centerYAnchor, constant: -alert.view.frame.height * 1/36 * 1/4).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: alert.view.frame.height * 4/36).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: alert.view.frame.height * 4/36).isActive = true
        
        let nameLabel = UILabel()
        nameLabel.font = UIFont.boldSystemFont(ofSize: alert.view.frame.height * 1/36 - 2)
        nameLabel.text = account.name
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        alert.view.addSubview(nameLabel)
        
        nameLabel.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor).isActive = true
        nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: alert.view.frame.height * 1/36 * 1/4).isActive = true
        nameLabel.widthAnchor.constraint(equalTo: alert.view.widthAnchor).isActive = true
        nameLabel.heightAnchor.constraint(equalToConstant: alert.view.frame.height * 1/36).isActive = true
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func handleGuess() {
        
        let accountViewController = AccountViewController()
        accountViewController.pretendingUser = account
        let navController = UINavigationController(rootViewController: accountViewController)
        present(navController, animated: true, completion: nil)
    }
    
    lazy var inputContainerView: UIView = {
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50)
        containerView.backgroundColor = UIColor.white
        
        let sendButton = UIButton(type: .system)
        containerView.addSubview(sendButton)
        
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.setTitle("Send", for: .normal)
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        
        containerView.addSubview(self.inputTextField)
        
        self.inputTextField.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 8).isActive = true
        self.inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor).isActive = true
        self.inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        self.inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        let separator = UIView()
        containerView.addSubview(separator)
        
        separator.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        separator.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        separator.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        separator.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        return containerView
    }()
    
    override var inputAccessoryView: UIView? {
        get {
            return inputContainerView
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(scrollToLastItem), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
    }
    
    @objc func scrollToLastItem() {
        let lastSectionIndex = collectionView!.numberOfSections - 1
        let lastItemIndex = collectionView!.numberOfItems(inSection: lastSectionIndex) - 1
        if lastItemIndex < 0 {
            return
        }
        self.collectionView?.scrollToItem(at: IndexPath(item: lastItemIndex, section: lastSectionIndex), at: .bottom, animated: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        guard let uid = Auth.auth().currentUser?.uid, let toId = account?.representedUserId else {
            return
        }
        let ref = Database.database().reference().child("user-messages").child(uid).child(toId)
        ref.removeAllObservers()
        setBadgeCount()
        
    }
    
    var pullingDown = false
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if(!pullingDown && scrollView.contentOffset.y < -100) {
            pullingDown = true
            observeMoreUserMessages()
        }
        if(scrollView.contentOffset.y > -80 && pullingDown) {
            pullingDown = false
        }
    }
    
    @objc func observeMoreUserMessages() {
        print("Observe more")
        if messages.count != 0 {
            guard let uid = Auth.auth().currentUser?.uid, let toId = account?.representedUserId else {
                return
            }
            let lastMessageId = messages[0].id
            let ref = Database.database().reference().child("user-messages").child(uid).child(toId).queryOrderedByKey().queryEnding(atValue: lastMessageId).queryLimited(toLast: 20)
            ref.observeSingleEvent(of: .value, with: {(snapshot) in
                if var dictionary = snapshot.value as? [String: String] {
                    dictionary.removeValue(forKey: lastMessageId!)
                    for message in dictionary {
                       self.fetchMoreMessage(messageId: message.key)
                    }
                }
            })
        }
    }
    
    private func fetchMoreMessage(messageId: String) {
        let messageRef = Database.database().reference().child("messages").child(messageId)
        messageRef.observeSingleEvent(of: .value, with: {(snapshot) in
            
            guard let dictionary = snapshot.value as? [String: Any] else {return}
            let message = Message()
            message.setValuesForKeys(dictionary)
            message.id = snapshot.key
            if !self.messages.contains{ $0.id == message.id } {
                self.messages.append(message)
                self.messages.sort(by: {($0.timestamp?.intValue)! < ($1.timestamp?.intValue)!})
                let itemRow = self.messages.index(of: message)
                let indexPath = IndexPath(row: itemRow!, section: 0)
                self.collectionView?.insertItems(at: [indexPath])
            }
        })
    }
    
    var messages = [Message]()
    
    @objc func observeUserMessages() {
        
        guard let uid = Auth.auth().currentUser?.uid, let toId = account?.representedUserId else {
            return
        }
        if messages.count > 0 {
            let lastMessageId = messages[messages.count - 1].id
            let ref = Database.database().reference().child("user-messages").child(uid).child(toId).queryOrderedByKey().queryStarting(atValue: lastMessageId).queryLimited(toLast: 20)
            ref.observe(.childAdded, with: {(snapshot) in
                let messageId = snapshot.key
                self.fetchMessage(messageId: messageId)
            })
        } else {
            let ref = Database.database().reference().child("user-messages").child(uid).child(toId).queryLimited(toLast: 20)
            ref.observe(.childAdded, with: {(snapshot) in
                let messageId = snapshot.key
                self.fetchMessage(messageId: messageId)
            })
        }
        
    }
    
    private func fetchMessage(messageId: String) {
        let messageRef = Database.database().reference().child("messages").child(messageId)
        messageRef.observeSingleEvent(of: .value, with: {(snapshot) in
            
            guard let dictionary = snapshot.value as? [String: Any] else {return}
            let message = Message()
            message.setValuesForKeys(dictionary)
            message.id = snapshot.key
            if !self.messages.contains{ $0.id == message.id } {
                self.messages.append(message)
                self.messages.sort(by: {($0.timestamp?.intValue)! < ($1.timestamp?.intValue)!})
                let itemRow = self.messages.index(of: message)
                let lastSectionIndex = self.collectionView!.numberOfSections - 1
                if itemRow == 0 {
                    let indexPath = IndexPath(row: 0, section: 0)
                    self.collectionView?.insertItems(at: [indexPath])
                } else {
                    let indexPath = IndexPath(row: itemRow!, section: lastSectionIndex)
                    self.collectionView?.insertItems(at: [indexPath])
                }
                self.scrollToLastItem()
            }
        })
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let ref = Database.database().reference().child("last-user-message-read").child(uid)
        ref.updateChildValues([account!.id!: 0])
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! MessageCell
        let message = messages[indexPath.row]
        cell.textView.text = message.message
        
        setupCell(cell: cell, message: message)
        return cell
    }
    
    private func setupCell(cell: MessageCell, message: Message) {
        
        cell.bubbleWidthAnchor?.constant = estimateFrameForText(text: message.message!).width + 32
        
        if message.fromId == Auth.auth().currentUser?.uid {
            cell.bubbleView.backgroundColor = MessageCell.blueColor
            cell.textView.textColor = UIColor.white
            cell.bubbleProfile.isHidden = true
            
            cell.bubbleRightAnchor?.isActive = true
            cell.bubbleLeftAnchor?.isActive = false
            
        } else {
            if let profileImageUrul = self.account?.profileImageUrl {
                cell.bubbleProfile.loadImagesFromCache(urlString: profileImageUrul)
            }
            
            cell.bubbleView.backgroundColor = MessageCell.grayColor
            cell.textView.textColor = UIColor.black
            cell.bubbleProfile.isHidden = false
            
            cell.bubbleRightAnchor?.isActive = false
            cell.bubbleLeftAnchor?.isActive = true
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 80
        if let text = messages[indexPath.row].message {
            height = estimateFrameForText(text: text).height + 20
        }
        let width = UIScreen.main.bounds.width
        return CGSize(width: width, height: height)
    }
    
    private func estimateFrameForText(text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    @objc func handleSend() {
        let ref = Database.database().reference().child("messages").childByAutoId()
        
        if let toId = account!.representedUserId, let impersonatingUserId = self.account!.impersonatingUserId, !inputTextField.text!.isEmpty {
            let fromId = Auth.auth().currentUser!.uid
            let timestamp = NSDate().timeIntervalSince1970
            let values = ["message": inputTextField.text!, "toId": toId,
                          "fromId": fromId, "timestamp": timestamp] as [String : Any]
            self.inputTextField.text = nil
            let lastRecipientMessageReadRef = Database.database().reference().child("last-user-message-read").child(toId).child(impersonatingUserId)
            lastRecipientMessageReadRef.runTransactionBlock({(currentCount) -> TransactionResult in
                if let count = currentCount.value as? Int {
                    currentCount.value = count + 1
                }
                return TransactionResult.success(withValue: currentCount)
            })
            
            ref.updateChildValues(values) {(error, ref) in
                if error != nil {
                    print(error!)
                    return
                }
                let userMessageRef = Database.database().reference().child("user-messages").child(fromId).child(toId)
                let messageId = ref.key
                userMessageRef.updateChildValues([messageId : self.account!.id!])
                
                let lastUserMessageRef = Database.database().reference().child("last-user-message").child(fromId)
                lastUserMessageRef.updateChildValues([self.account!.id! : [messageId: impersonatingUserId]])
                
                let recipientMessageRef = Database.database().reference().child("user-messages").child(toId).child(fromId)
                recipientMessageRef.updateChildValues([messageId : impersonatingUserId])
                
                let lastRecipientMessageRef = Database.database().reference().child("last-user-message").child(toId)
                lastRecipientMessageRef.updateChildValues([impersonatingUserId : [messageId: self.account!.id!]])
            }
        }
    }
    
    
    var accounts: [Account]?
    
    func findARepresentation() {
        print("Finding a representation....")
        if accounts != nil {
            var unRepresentedUsers = [Account]()
            
            for user in accounts! {
                var represented = false
                for user1 in accounts! {
                    if(user1.representedUserId == user.id) {
                        represented = true
                        break
                    }
                }
                if !represented {
                    unRepresentedUsers.append(user)
                }
            }
            
            if unRepresentedUsers.count > 0 {
                var represent = unRepresentedUsers[0]
                if unRepresentedUsers.count > 1 {
                    represent = unRepresentedUsers[Int(arc4random_uniform(UInt32(unRepresentedUsers.count)))]
                }
                account?.representedUserId = represent.id
                
                findAImpersonation()
            }
        }
    }
    
    
    var unRepresentingUserIds = [String]()
    let group = DispatchGroup()
    
    func findAImpersonation() {
        print("Finding a impersonating...")
        
        let ref = Database.database().reference().child("connections").child(account!.representedUserId!)
            .queryOrderedByValue().queryEqual(toValue: "none")
        ref.observe(.childAdded, with: {(snapshot) in
            self.group.enter()
            self.unRepresentingUserIds.append(snapshot.key)
            if self.unRepresentingUserIds.count == 1 {
                self.group.notify(queue: .main, execute: {
                    self.updateImpersonation()
                })
            }
            self.group.leave()
        })
    }
    
    
    @objc func updateImpersonation() {
        
        if unRepresentingUserIds.count > 0 {
            var impersonatingUserId = unRepresentingUserIds[0]
            if unRepresentingUserIds.count > 1 {
                impersonatingUserId = unRepresentingUserIds[Int(arc4random_uniform(UInt32(unRepresentingUserIds.count)))]
            }
            
            guard let uid = Auth.auth().currentUser?.uid else {return}
            
            account?.impersonatingUserId = impersonatingUserId
            let connectionRef = Database.database().reference().child("connections").child(uid)
            connectionRef.updateChildValues([account!.id! : [account!.representedUserId!: impersonatingUserId]])
            
            let connectionRef1 = Database.database().reference().child("connections").child(account!.representedUserId!)
            connectionRef1.updateChildValues([impersonatingUserId : [uid: account!.id]])
            print("representing/impersonating setup")
            
            let readRef = Database.database().reference().child("last-user-message-read").child(uid)
            readRef.updateChildValues([self.account!.id! : 0])
            let readRef1 = Database.database().reference().child("last-user-message-read").child(account!.representedUserId!)
            readRef1.updateChildValues([impersonatingUserId : 0])
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
}
