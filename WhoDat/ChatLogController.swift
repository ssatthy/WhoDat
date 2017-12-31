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
            if account?.toId == "none" {
                setupAnonymousId()
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
    
    @objc func showReportOptions()  {
        print("show options")
        let alert = UIAlertController(title: "Report This User", message: "If you find this user abusive or his/her messages are objectionable, You can either block or report it.", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Report", style: .default, handler: { _ in
            self.reportUser()
        }))
        alert.addAction(UIAlertAction(title: "Block", style: .default, handler: { _ in
            self.blockUser()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func reportUser() {
        let alert = UIAlertController(title: "Report This User", message: "Tell us little bit about the experience with user.", preferredStyle: .alert)
        alert.addTextField { (textField) in
                textField.placeholder = "Enter here..."
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Report", style: .default, handler: { _ in
            
            if let textField = alert.textFields?[0], let text = textField.text {
                let ref = Database.database().reference().child(Configuration.environment).child("user-report").child(LocalUserRepository.currentUid)
                let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .long)
                if self.account!.anonymous {
                    ref.updateChildValues([ self.account!.toId! + timestamp : text])
                } else {
                    ref.updateChildValues([ self.account!.id! + timestamp : text])
                }
            }
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func blockUser() {
        let alert = UIAlertController(title: "Block This User", message: "You both cannot send or receive message if you do so.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Block", style: .destructive, handler: { _ in
            
            if self.account!.anonymous {
                AccountViewController().endAnonymousChat(account: self.account!, stage: "ended")
                
                let ref = Database.database().reference().child(Configuration.environment).child("blocked-users").child(LocalUserRepository.currentUid)
                let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .long)
                ref.updateChildValues([ self.account!.toId! : timestamp])
                
                let ref1 = Database.database().reference().child(Configuration.environment).child("blocked-users").child(self.account!.toId!)
                ref1.updateChildValues([ LocalUserRepository.currentUid : "reverse block"])
            } else {
                AccountViewController().endChat(account: self.account!)
                
                let ref = Database.database().reference().child(Configuration.environment).child("blocked-users").child(LocalUserRepository.currentUid)
                let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .long)
                ref.updateChildValues([ self.account!.id! : timestamp])
                
                let ref1 = Database.database().reference().child(Configuration.environment).child("blocked-users").child(self.account!.id!)
                ref1.updateChildValues([ LocalUserRepository.currentUid : "reverse block"])
            }
            
        }))
        
        self.present(alert, animated: true, completion: nil)
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
    }
    
    @objc func showAds() {
        if interstitial.isReady {
            interstitial.present(fromRootViewController: self)
        }
    }
    func observeAlert() {
        print("setup alert observe")
        if account!.anonymous {
            let ref = Database.database().reference().child(Configuration.environment).child("anonymous-users").child(account!.id!)
            ref.observe(.childRemoved, with: {(snapshot) in
                if self.account!.found == "found" {
                    let alert = UIAlertController(title: "Well Done!", message: "You have caught this person.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: {(_) in
                        self.navigationController?.popViewController(animated: true)
                    }))
                    self.present(alert, animated: true, completion: nil)
                    
                    self.account!.found = "none"
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
            })
        } else if account?.toId != "none" {
            let ref = Database.database().reference().child(Configuration.environment).child("anonymous-users").child(account!.toId!)
            ref.observe(.childRemoved, with: {(snapshot) in
                self.navigationController?.popViewController(animated: true)
                
            })
        }
        
    }
    
    var guessButton: UIBarButtonItem?
    var missedButton: UIBarButtonItem?
    
    func setGuessButton() {
        if account!.anonymous {
            self.guessButton = UIBarButtonItem(title: "Who?", style: .plain, target: self, action: #selector(handleGuess))
            self.guessButton?.tintColor = UIColor.red
            navigationItem.rightBarButtonItem = guessButton
            
            let infoMissed = UIButton(type: .infoDark)
            infoMissed.addTarget(self, action: #selector(showMissed), for: .touchUpInside)
            self.missedButton = UIBarButtonItem(customView: infoMissed)
            
            observeFailedAttempt()
        } else {
            let info = UIButton(type: .infoDark)
            info.addTarget(self, action: #selector(showInfo), for: .touchUpInside)
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: info)
        }
    }
    
    func observeFailedAttempt() {
        Database.database().reference().child(Configuration.environment).child("failed-attempt").child(LocalUserRepository.currentUid).child(account!.id!).observe(.value, with: {(snapshot) in
            if let _ = snapshot.value as? Int {
                if self.account!.found == "missed" {
                    let alert = UIAlertController(title: "You Missed It!", message: "You had one chance. But you failed to guess this person correctly.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    
                    self.account!.found = "none"
                }
                self.navigationItem.rightBarButtonItem = self.missedButton
                
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        observeUserMessages()
        setupKeyboardObservers()
        
        let lastRecipientMessageReadRef = Database.database().reference().child(Configuration.environment).child("last-user-message-read").child(LocalUserRepository.currentUid).child(account!.id!)
        lastRecipientMessageReadRef.runTransactionBlock({(currentCount) -> TransactionResult in
            if let _ = currentCount.value as? Int {
                currentCount.value = 0
            }
            return TransactionResult.success(withValue: currentCount)
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setBadgeCount()
    }
    
    func setBadgeCount() {
        let ref = Database.database().reference().child(Configuration.environment).child("last-user-message-read").child(LocalUserRepository.currentUid)
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
    
    @objc func showMissed() {
        let alert = UIAlertController(title: "You Missed It", message: "You failed to guess this person correctly.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "End Chat", style: .default, handler: {(_) in
          AccountViewController().endAnonymousChat(account: self.account!, stage: "ended")
            self.showAds()
        }))
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: {(_) in
            self.showAds()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func showInfo() {
        let alert = UIAlertController(title: "End Chat", message: "Do you like to end this chat?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "End Chat", style: .default, handler: {(_) in
            AccountViewController().endChat(account: self.account!)
            self.showAds()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: {(_) in
            self.showAds()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func handleGuess() {
        
        let accountViewController = AccountViewController()
        account?.found = "none"
        accountViewController.account = account
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
        let ref = Database.database().reference().child(Configuration.environment).child("user-messages").child(LocalUserRepository.currentUid).child(self.account!.id!)
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
            guard let toId = account?.toId else {
                return
            }
            let lastMessageId = messages[0].id
            let ref = Database.database().reference().child(Configuration.environment).child("user-messages").child(LocalUserRepository.currentUid).child(toId).queryOrderedByKey().queryEnding(atValue: lastMessageId).queryLimited(toLast: 20)
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
        let messageRef = Database.database().reference().child(Configuration.environment).child("messages").child(messageId)
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
        
        if messages.count > 0 {
            let lastMessageId = messages[messages.count - 1].id
            let ref = Database.database().reference().child(Configuration.environment).child("user-messages").child(LocalUserRepository.currentUid).child(account!.id!).queryOrderedByKey().queryStarting(atValue: lastMessageId).queryLimited(toLast: 20)
            ref.observe(.childAdded, with: {(snapshot) in
                let messageId = snapshot.key
                self.fetchMessage(messageId: messageId)
            })
        } else {
            let ref = Database.database().reference().child(Configuration.environment).child("user-messages").child(LocalUserRepository.currentUid).child(account!.id!).queryLimited(toLast: 20)
            ref.observe(.childAdded, with: {(snapshot) in
                let messageId = snapshot.key
                self.fetchMessage(messageId: messageId)
            })
        }
        
    }
    
    private func fetchMessage(messageId: String) {
        let messageRef = Database.database().reference().child(Configuration.environment).child("messages").child(messageId)
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
        
        let ref = Database.database().reference().child(Configuration.environment).child("last-user-message-read").child(LocalUserRepository.currentUid)
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
        
        if (account!.anonymous && message.fromId == LocalUserRepository.currentUid) || (!account!.anonymous && message.fromId == account!.toId!) {
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
            cell.contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showReportOptions)))
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
        if inputTextField.text!.isEmpty { return }
        let ref = Database.database().reference().child(Configuration.environment).child("messages").childByAutoId()
        if account!.anonymous {
            let timestamp = NSDate().timeIntervalSince1970
            let values = ["message": inputTextField.text!, "toId": account!.toId!,
                          "fromId": LocalUserRepository.currentUid, "timestamp": timestamp] as [String : Any]
            self.inputTextField.text = nil
            let lastRecipientMessageReadRef = Database.database().reference().child(Configuration.environment).child("last-user-message-read").child(account!.toId!).child(LocalUserRepository.currentUid)
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
                let userMessageRef = Database.database().reference().child(Configuration.environment).child("user-messages").child(LocalUserRepository.currentUid).child(self.account!.id!)
                let messageId = ref.key
                userMessageRef.updateChildValues([messageId : 0])
                
                let lastUserMessageRef = Database.database().reference().child(Configuration.environment).child("last-user-message").child(LocalUserRepository.currentUid)
                lastUserMessageRef.updateChildValues([self.account!.id! : [messageId : self.account!.toId!]])
                
                let recipientMessageRef = Database.database().reference().child(Configuration.environment).child("user-messages").child(self.account!.toId!).child(LocalUserRepository.currentUid)
                recipientMessageRef.updateChildValues([messageId : 0])
                
                let lastRecipientMessageRef = Database.database().reference().child(Configuration.environment).child("last-user-message").child(self.account!.toId!)
                lastRecipientMessageRef.updateChildValues([LocalUserRepository.currentUid : [messageId : self.account!.id!]])
            }
        } else {
            let timestamp = NSDate().timeIntervalSince1970
            let values = ["message": inputTextField.text!, "toId": account!.id!,
                          "fromId": account!.toId!, "timestamp": timestamp] as [String : Any]
            self.inputTextField.text = nil
            let lastRecipientMessageReadRef = Database.database().reference().child(Configuration.environment).child("last-user-message-read").child(account!.id!).child(account!.toId!)
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
                let userMessageRef = Database.database().reference().child(Configuration.environment).child("user-messages").child(LocalUserRepository.currentUid).child(self.account!.id!)
                let messageId = ref.key
                userMessageRef.updateChildValues([messageId : 0])
                
                let lastUserMessageRef = Database.database().reference().child(Configuration.environment).child("last-user-message").child(LocalUserRepository.currentUid)
                lastUserMessageRef.updateChildValues([self.account!.id! : [messageId : self.account!.toId!]])
                
                let recipientMessageRef = Database.database().reference().child(Configuration.environment).child("user-messages").child(self.account!.id!).child(self.account!.toId!)
                recipientMessageRef.updateChildValues([messageId : 0])
                
                let lastRecipientMessageRef = Database.database().reference().child(Configuration.environment).child("last-user-message").child(self.account!.id!)
                lastRecipientMessageRef.updateChildValues([self.account!.toId! : [messageId : LocalUserRepository.currentUid]])
            }
        }
    }
    
    func setupAnonymousId() {
        print("Setting up an anonymous id....")
        let randomId = String(Date().timeIntervalSince1970.hashValue).suffix(3)
        let ref = Database.database().reference().child(Configuration.environment).child("anonymous-users").childByAutoId()
        ref.updateChildValues([self.account!.id!: "Anonymous \(randomId)"]) { (error, ref) in
            self.account?.toId = ref.key
            let connectionRef = Database.database().reference().child(Configuration.environment).child("connections").child(LocalUserRepository.currentUid)
            connectionRef.updateChildValues([self.account!.id! : ref.key])
            
            let messageReadRef = Database.database().reference().child(Configuration.environment).child("last-user-message-read").child(LocalUserRepository.currentUid)
            messageReadRef.updateChildValues([self.account!.id!: 0])
            let messageReadRef1 = Database.database().reference().child(Configuration.environment).child("last-user-message-read").child(self.account!.id!)
            messageReadRef1.updateChildValues([self.account!.toId!: 0])
            
            let ref = Database.database().reference().child(Configuration.environment).child("anonymous-users").child(self.account!.toId!)
            ref.observe(.childRemoved, with: {(snapshot) in
                self.navigationController?.popViewController(animated: true)
                
            })
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
}
