//
//  ChatLogController.swift
//  WhoDat
//
//  Created by Sathyavarathan Sivabalasingam on 10/15/17.
//  Copyright © 2017 LTAC. All rights reserved.
//

import UIKit
import Firebase

class ChatLogController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout {
    
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
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setGuessButton()
        observeUserMessages()
    }
    
    func setGuessButton() {
        let guessButton = UIBarButtonItem(title: "Who?", style: .plain, target: self, action: #selector(handleGuess))
        guessButton.tintColor = UIColor.red
        navigationItem.rightBarButtonItem = guessButton
        
        setAttention()
    }
    
    private func setAttention() {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        let foundIndicator = navigationItem.titleView?.viewWithTag(111)
        foundIndicator?.backgroundColor = navigationItem.titleView?.backgroundColor
        
        let refCaught = Database.database().reference().child("users-caught").child(uid).queryOrderedByKey()
            .queryEqual(toValue: account?.id!)
        refCaught.observe(.childAdded, with: {(snapshot) in
            foundIndicator?.backgroundColor = UIColor(r: 61, g: 151, b: 61)
        })
        
        let refBeenCaught = Database.database().reference().child("users-caught").child(account!.representedUserId!).queryOrderedByKey().queryEqual(toValue: uid)
        refBeenCaught.observe(.childAdded, with: {(snapshot) in
            foundIndicator?.backgroundColor = UIColor(r: 151, g: 61, b: 61)
        })
    }

    
    func handleGuess() {
        
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    var messages = [Message]()
    
    func observeUserMessages() {
        messages = [Message]()
        guard let uid = Auth.auth().currentUser?.uid, let toId = account?.representedUserId else {
            return
        }
        
        let ref = Database.database().reference().child("user-messages").child(uid).child(toId)
        ref.observe(.childAdded, with: {(snapshot) in
            
            let messageId = snapshot.key
            self.fetchMessage(messageId: messageId)
        })
    }
    
    private func fetchMessage(messageId: String) {
        let messageRef = Database.database().reference().child("messages").child(messageId)
        messageRef.observeSingleEvent(of: .value, with: {(snapshot) in
            
            guard let dictionary = snapshot.value as? [String: Any] else {return}
            
            let message = Message()
            message.setValuesForKeys(dictionary)
            self.messages.append(message)
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
            }
            
            
        })
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
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    func handleSend() {
        let ref = Database.database().reference().child("messages").childByAutoId()
        
        if let toId = account!.representedUserId, !inputTextField.text!.isEmpty {
            let fromId = Auth.auth().currentUser!.uid
            let timestamp = NSDate().timeIntervalSince1970
            let values = ["message": inputTextField.text!, "toId": toId,
                          "fromId": fromId, "timestamp": timestamp] as [String : Any]
            ref.updateChildValues(values) {(error, ref) in
                if error != nil {
                    print(error!)
                    return
                }
                
                self.inputTextField.text = nil
                
                let userMessageRef = Database.database().reference().child("user-messages").child(fromId).child(toId)
                let messageId = ref.key
                userMessageRef.updateChildValues([messageId : self.account!.id!])
                
                let lastUserMessageRef = Database.database().reference().child("last-user-message").child(fromId)
                lastUserMessageRef.updateChildValues([self.account!.id! : messageId])
                
                
                let recipientMessageRef = Database.database().reference().child("user-messages").child(toId).child(fromId)
                recipientMessageRef.updateChildValues([messageId : self.account!.impersonatingUserId!])
                
                let lastRecipientMessageRef = Database.database().reference().child("last-user-message").child(toId)
                lastRecipientMessageRef.updateChildValues([self.account!.impersonatingUserId! : messageId ])
                
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
                guard let uid = Auth.auth().currentUser?.uid else {
                    return
                }
                
                
                let connectionRef = Database.database().reference().child("connections").child(uid)
                connectionRef.updateChildValues([account!.id! : represent.id!])
                findAImpersonation()
            }
        }
    }
    
    
    var unRepresentingUserIds = [String]()
    
    func findAImpersonation() {
        print("Finding a impersonating...")
        
        let ref = Database.database().reference().child("connections").child(account!.representedUserId!)
            .queryOrderedByValue().queryEqual(toValue: "none")
        ref.observe(.childAdded, with: {(snapshot) in
            self.unRepresentingUserIds.append(snapshot.key)
        })
        
        waitForDataToBeFetched()
    }
    
    
    func updateImpersonation() {
        
        if unRepresentingUserIds.count > 0 {
            var impersonatingUserId = unRepresentingUserIds[0]
            if unRepresentingUserIds.count > 1 {
                impersonatingUserId = unRepresentingUserIds[Int(arc4random_uniform(UInt32(unRepresentingUserIds.count)))]
            }
            
            guard let uid = Auth.auth().currentUser?.uid else {return}
            
            account?.impersonatingUserId = impersonatingUserId
            let connectionRef = Database.database().reference().child("connections").child(account!.representedUserId!)
            connectionRef.updateChildValues([impersonatingUserId : uid])
        }
    }
    
    var timer: Timer?
    
    private func waitForDataToBeFetched() {
        self.timer?.invalidate()
        
        self.timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.updateImpersonation), userInfo: nil, repeats: false)
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
}