//
//  ViewController.swift
//  WhoDat
//
//  Created by Sathyavarathan Sivabalasingam on 10/14/17.
//  Copyright © 2017 LTAC. All rights reserved.
//

import UIKit
import Firebase
import GoogleMobileAds

class MessageController: UITableViewController, GADBannerViewDelegate {
    
    var messages = [Message]()
    
    var chatLogControllers = [String: ChatLogController]()
    
    var bannerView: GADBannerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        
        checkIfUserIsLoggedIn()
        let image = UIImage(named: "new_message_icon")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(handleNewMessage))
        
        bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        bannerView.adUnitID = "ca-app-pub-2292982215135045/2290201824"
        bannerView.rootViewController = self
        bannerView.delegate = self
        let request = GADRequest()
        request.testDevices = [kGADSimulatorID]
        bannerView.load(request)
        
    }
    
    lazy var adContainerView: UIView = {
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: bannerView.frame.size.width, height: bannerView.frame.size.height)
        containerView.backgroundColor = UIColor.white
        containerView.addSubview(bannerView)
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        bannerView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        bannerView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        bannerView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        
        
        return containerView
    }()
    
    override var inputAccessoryView: UIView? {
        get {
            return adContainerView
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    let operations = OperationQueue()
    let group = DispatchGroup()
    
    func observeAddedMessages() {
        print("observe added msg")
        let ref = Database.database().reference().child(Configuration.environment).child("last-user-message").child(LocalUserRepository.currentUid)
        ref.observe(.childAdded, with: {(snapshot) in
            self.group.enter()
            print("enter")
            let userId = snapshot.key
            let map = snapshot.value as! [String: String]
            let messageId = Array(map)[0].key
            let toUserId = Array(map)[0].value
            let messageRef = Database.database().reference().child(Configuration.environment).child("messages").child(messageId)
            messageRef.observeSingleEvent(of: .value, with: {(snapshot) in
                if let dictionary = snapshot.value as? [String: Any] {
                    let message = Message()
                    message.id = messageId
                    message.setValuesForKeys(dictionary)
                    
                    if let account = LocalUserRepository.shared().loadUserFromCache(uid: userId) {
                        message.account = account
                        self.setupMessage(message: message)
                        self.group.leave()
                        print("leave")
                    } else {
                       let ref = Database.database().reference().child(Configuration.environment).child("users").child(userId)
                        ref.observeSingleEvent(of: .value, with: {(snapshot) in
                            if let dictionary = snapshot.value as? [String: AnyObject] {
                                let account = Account()
                                account.id = userId
                                account.setValuesForKeys(dictionary)
                                account.toId = toUserId
                                LocalUserRepository.shared().setObject(account)
                                
                                message.account = account
                                self.setupMessage(message: message)
                                self.group.leave()
                                print("leave")
                            } else {
                                let ref = Database.database().reference().child(Configuration.environment).child("anonymous-users").child(userId)
                                ref.observeSingleEvent(of: .value, with: {(snapshot) in
                                    if let dictionary = snapshot.value as? [String: String] {
                                        let account = Account()
                                        account.id = userId
                                        account.toId = toUserId
                                        account.name = Array(dictionary)[0].value
                                        account.anonymous = true
                                        LocalUserRepository.shared().setObject(account)
                                        
                                        message.account = account
                                        self.setupMessage(message: message)
                                        self.group.leave()
                                        print("leave")
                                    }
                                })
                            }
                        })
                    }
                }
            })
        })
    }
    
    func observeChangedMessages() {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference().child(Configuration.environment).child("last-user-message").child(uid)
        ref.observe(.childChanged, with: {(snapshot) in
            let userId = snapshot.key
            let map = snapshot.value as! [String: String]
            let messageId = Array(map)[0].key
            let toUserId = Array(map)[0].value
            let messageRef = Database.database().reference().child(Configuration.environment).child("messages").child(messageId)
            messageRef.observeSingleEvent(of: .value, with: {(snapshot) in
                if let dictionary = snapshot.value as? [String: Any] {
                    let message = Message()
                    message.id = messageId
                    message.setValuesForKeys(dictionary)
                    
                    if let account = LocalUserRepository.shared().loadUserFromCache(uid: userId) {
                        message.account = account
                        self.setupMessage(message: message)
                    } else {
                        Database.database().reference().child(Configuration.environment).child("users").child(userId).observeSingleEvent(of: .value, with: {(snapshot) in
                            if let dictionary = snapshot.value as? [String: AnyObject] {
                                let account = Account()
                                account.id = userId
                                account.setValuesForKeys(dictionary)
                                account.toId = toUserId
                                LocalUserRepository.shared().setObject(account)
                                
                                message.account = account
                                self.setupMessage(message: message)
                            } else {
                                let ref = Database.database().reference().child(Configuration.environment).child("anonymous-users").child(userId)
                                ref.observeSingleEvent(of: .value, with: {(snapshot) in
                                    if let dictionary = snapshot.value as? [String: String] {
                                        let account = Account()
                                        account.id = userId
                                        account.toId = toUserId
                                        account.name = Array(dictionary)[0].value
                                        account.anonymous = true
                                        LocalUserRepository.shared().setObject(account)
                                        
                                        message.account = account
                                        self.setupMessage(message: message)
                                        self.group.leave()
                                        print("leave")
                                    }
                                })
                            }
                        })
                    }
                }
            })
        })
    }

    func observeRemovedMessage() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference().child(Configuration.environment).child("last-user-message").child(uid)
        ref.observe(.childRemoved, with: {(snapshot) in
            let accountId = snapshot.key
            let map = snapshot.value as! [String: String]
            let messageId = Array(map)[0].key
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            let delay = Int(1 * Double(1000))
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(delay), execute: {
                self.messages = self.messages.filter{ $0.id != messageId }
                self.chatLogControllers[accountId] = nil
                self.tableView.reloadData()
            })
        })
    }
    
    func setupMessage(message: Message) {
        print("done")
        messages = messages.filter{ $0.account?.id != message.account?.id! }
        self.messages.append(message)
        
        group.notify(queue: .main, execute: {
            if self.operations.operationCount == 0 {
                self.operations.addOperation {
                    self.messages.sort(by: {(message1, message2) -> Bool in
                        return (message1.timestamp?.intValue)! > (message2.timestamp?.intValue)!
                    })
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
        })
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: message.account!.id!) {
            let cell1 = cell as! AccountCell
            cell1.message = message
            return cell
        } else {
            tableView.register(AccountCell.self, forCellReuseIdentifier: message.account!.id!)
            let cell = tableView.dequeueReusableCell(withIdentifier: message.account!.id!, for: indexPath) as! AccountCell
            cell.message = message
            return cell
        }
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.row]
        
        self.showChatLogController(selectedAccount: message.account!)
    }
    
    @objc func handleNewMessage() {
        let newMessageController = NewMessageController()
        newMessageController.messageController = self
        let navController = UINavigationController(rootViewController: newMessageController)
        present(navController, animated: true, completion: nil)
        
    }
    
    func checkIfUserIsLoggedIn() {
        if((Auth.auth().currentUser) == nil) {
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
        } else {
            print("fetch user details")
            fetchUserAndSetNavBar()
        }

    }
    
    func fetchUserAndSetNavBar() {
        
        if let account = LocalUserRepository.shared().loadUserFromCache(uid: LocalUserRepository.currentUid) {
            self.setNavBar(account: account)
        } else {
            Database.database().reference().child(Configuration.environment).child("users").child(LocalUserRepository.currentUid).observeSingleEvent(of: .value, with:
                {(snapshot) in
                    if let dictionary = snapshot.value as? [String: AnyObject] {
                        print(dictionary)
                        let account = Account()
                        account.setValuesForKeys(dictionary)
                        account.id = LocalUserRepository.currentUid
                        LocalUserRepository.shared().setObject(account)
                        self.setNavBar(account: account)
                    }
            })
        }
        resetMessages()
    }
    
    func resetMessages() {
        
        messages.removeAll()
        tableView.reloadData()
        chatLogControllers = [String: ChatLogController]()
        
        observeAddedMessages()
        observeChangedMessages()
        observeRemovedMessage()
    }
    
    func showChatLogController(selectedAccount: Account) {
        if let chatLogController = chatLogControllers[selectedAccount.id!] {
            navigationController?.pushViewController(chatLogController, animated: true)
        } else {
            let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
            chatLogController.account = selectedAccount
            chatLogControllers[selectedAccount.id!] = chatLogController
            navigationController?.pushViewController(chatLogController, animated: true)
        }
        
    }
    
    @objc func handleLogout() {
        let uid = Auth.auth().currentUser?.uid
        do {
            try Auth.auth().signOut()
        } catch let logoutError {
            print(logoutError)
        }
        let loginController = LoginController()
        loginController.messageController = self
        present(loginController, animated: true, completion: nil)
        
        guard let uidValue = uid else {return}
        let ref = Database.database().reference().child(Configuration.environment).child("users").child(uidValue).child("token")
        ref.setValue("none")
        
    }
    
}

