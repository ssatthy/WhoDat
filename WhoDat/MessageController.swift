//
//  ViewController.swift
//  WhoDat
//
//  Created by Sathyavarathan Sivabalasingam on 10/14/17.
//  Copyright © 2017 LTAC. All rights reserved.
//

import UIKit
import Firebase

class MessageController: UITableViewController {

    var messages = [Message]()
    
    let cellId = "cellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        
        checkIfUserIsLoggedIn()
        resetMessages()
        tableView.register(AccountCell.self, forCellReuseIdentifier: cellId)
        
        let image = UIImage(named: "new_message_icon")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(handleNewMessage))
    }
    
    func observeAddedMessages() {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference().child("last-user-message").child(uid)
        ref.observe(.childAdded, with: {(snapshot) in
            let pretendingUserId = snapshot.key
            let messageId = snapshot.value as! String
            let messageRef = Database.database().reference().child("messages").child(messageId)
            messageRef.observeSingleEvent(of: .value, with: {(snapshot) in
                if let dictionary = snapshot.value as? [String: Any] {
                    let message = Message()
                    message.setValuesForKeys(dictionary)
                    
                    if let account = self.loadUserFromCache(uid: pretendingUserId) {
                        message.account = account
                        self.setupMessage(message: message)
                    } else {
                        Database.database().reference().child("users").child(pretendingUserId).observeSingleEvent(of: .value, with: {(snapshot) in
                            if let dictionary = snapshot.value as? [String: AnyObject] {
                                let account = Account()
                                account.id = snapshot.key
                                account.setValuesForKeys(dictionary)
                                userCache.setObject(account, forKey: account.id as AnyObject)
                                
                                message.account = account
                                self.setupMessage(message: message)
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
        let ref = Database.database().reference().child("last-user-message").child(uid)
        ref.observe(.childChanged, with: {(snapshot) in
            let pretendingUserId = snapshot.key
            let messageId = snapshot.value as! String
            let messageRef = Database.database().reference().child("messages").child(messageId)
            messageRef.observeSingleEvent(of: .value, with: {(snapshot) in
                if let dictionary = snapshot.value as? [String: Any] {
                    let message = Message()
                    message.setValuesForKeys(dictionary)
                    
                    if let account = self.loadUserFromCache(uid: pretendingUserId) {
                        message.account = account
                        self.setupMessage(message: message)
                    } else {
                        Database.database().reference().child("users").child(pretendingUserId).observeSingleEvent(of: .value, with: {(snapshot) in
                            if let dictionary = snapshot.value as? [String: AnyObject] {
                                let account = Account()
                                account.id = snapshot.key
                                account.setValuesForKeys(dictionary)
                                userCache.setObject(account, forKey: account.id as AnyObject)
                                
                                message.account = account
                                self.setupMessage(message: message)
                            }
                        })
                    }
                }
            })
        })
        
    }
    
    func setupMessage(message: Message) {
        message.account?.representedUserId = message.representedUserId()!
        self.setImpersonatingUserId(representedUserId: message.representedUserId()!, account: message.account!)
        messages = messages.filter{ $0.account?.id != message.account?.id! }
        self.messages.append(message)
        //self.attemptToReloadOfTable()
        self.messages.sort(by: {(message1, message2) -> Bool in
            return (message1.timestamp?.intValue)! > (message2.timestamp?.intValue)!
        })
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    var timer: Timer?
    
    private func attemptToReloadOfTable() {
        self.timer?.invalidate()
        
        self.timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(self.handleReloadTable), userInfo: nil, repeats: false)
    }
    
    
    @objc func handleReloadTable() {
        self.messages.sort(by: {(message1, message2) -> Bool in
            return (message1.timestamp?.intValue)! > (message2.timestamp?.intValue)!
        })
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! AccountCell
        let message = messages[indexPath.row]
        cell.message = message
        return cell
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
            fetchUserAndSetNavBar()
        }

    }
    
    func fetchUserAndSetNavBar() {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        if let account = loadUserFromCache(uid: uid) {
            self.setNavBar(account: account)
        } else {
            Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with:
                {(snapshot) in
                    if let dictionary = snapshot.value as? [String: AnyObject] {
                        print(dictionary)
                        let account = Account()
                        account.setValuesForKeys(dictionary)
                        account.id = uid
                        userCache.setObject(account, forKey: account.id as AnyObject)
                        self.setNavBar(account: account)
                    }
            })
        }
        
    }
    
    func resetMessages() {
        messages.removeAll()
        tableView.reloadData()
        
        observeAddedMessages()
        observeChangedMessages()
    }
    
    func showChatLogController(selectedAccount: Account) {
        let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.account = selectedAccount
        navigationController?.pushViewController(chatLogController, animated: true)
    }
    
    func showChatLogController(selectedAccount: Account, accounts: [Account]) {
        let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.accounts = accounts
        chatLogController.account = selectedAccount
        navigationController?.pushViewController(chatLogController, animated: true)
    }
    
    @objc func handleLogout() {
        
        do {
            try Auth.auth().signOut()
        } catch let logoutError {
            print(logoutError)
        }
        let loginController = LoginController()
        loginController.messageController = self
        present(loginController, animated: true, completion: nil)
        
    }
    
}

