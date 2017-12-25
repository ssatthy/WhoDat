//
//  AccountController.swift
//  WhoDat
//
//  Created by Sathy on 10/25/17.
//  Copyright © 2017 LTAC. All rights reserved.
//

import UIKit
import Firebase

class AccountViewController: UITableViewController {
    
    let cellId = "cellId"
    var accounts = [Account]()
    var account: Account?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        navigationItem.title = "Guess a friend"
        
        tableView.register(AccountCell.self, forCellReuseIdentifier: cellId)
        fetchUsers()
    }
    
    func fetchUsers() {
        Database.database().reference().child(Configuration.environment).child("connections").child(LocalUserRepository.currentUid).observeSingleEvent(of: .value, with:
            {(snapshot) in
                if let connections = snapshot.value as? [String: String] {
                    for connection in connections {
                        if let account = LocalUserRepository.shared().loadUserFromCache(uid: connection.key) {
                            self.accounts.append(account)
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                        } else {
                            let userRef = Database.database().reference().child(Configuration.environment).child("users").child(connection.key)
                            userRef.observeSingleEvent(of: .value, with: {(snapshot) in
                                if let dictionary = snapshot.value as? [String: AnyObject] {
                                    let account = Account()
                                    account.id = connection.key
                                    account.setValuesForKeys(dictionary)
                                    account.toId = connection.value
                                    LocalUserRepository.shared().setObject(account)
                                    
                                    self.accounts.append(account)
                                    DispatchQueue.main.async {
                                        self.tableView.reloadData()
                                    }
                                }
                                
                            })
                        }
                    }
                }
        })
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.accounts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! AccountCell
        
        let user = self.accounts[indexPath.row]
        cell.textLabel?.text = user.name
        cell.detailTextLabel?.text = user.phone
        
        if let imageFileUrl = user.profileImageUrl {
            cell.profileImageView.loadImagesFromCache(urlString: imageFileUrl)
        }
        
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    @objc func handleCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true, completion: {
            let selectedAccount = self.accounts[indexPath.row]
            if self.account?.toId == selectedAccount.id {
                self.endAnonymousChat(account: self.account!, stage: "caught")
                self.account?.found = "found"
            } else {
                let ref = Database.database().reference().child(Configuration.environment).child("failed-attempt").child(LocalUserRepository.currentUid)
                ref.updateChildValues([self.account!.id! : 0])
                self.account?.found = "missed"
                
            }
        })
    }
    
    func endAnonymousChat(account: Account, stage: String) {
        let refLastMessage = Database.database().reference().child(Configuration.environment).child("last-user-message").child(LocalUserRepository.currentUid).child(account.id!)
        refLastMessage.removeValue()
        let refLastMessage2 = Database.database().reference().child(Configuration.environment).child("last-user-message").child(account.toId!).child(LocalUserRepository.currentUid)
        refLastMessage2.removeValue()
        let readRef = Database.database().reference().child(Configuration.environment).child("last-user-message-read").child(LocalUserRepository.currentUid).child(account.id!)
        readRef.removeValue()
        let readRef1 = Database.database().reference().child(Configuration.environment).child("last-user-message-read").child(account.toId!).child(LocalUserRepository.currentUid)
        readRef1.removeValue()
        
        let refConnection = Database.database().reference().child(Configuration.environment).child("connections").child(account.toId!)
        refConnection.updateChildValues([LocalUserRepository.currentUid : "none"])
        let refUserMessage = Database.database().reference().child(Configuration.environment).child("user-messages").child(LocalUserRepository.currentUid).child(account.id!)
        refUserMessage.observeSingleEvent(of: .value, with: {(snapshot) in
            if let dictionary = snapshot.value as? [String: Int] {
                for map in dictionary {
                    let messageId = map.key
                    let refMessage = Database.database().reference().child(Configuration.environment).child("messages").child(messageId)
                    refMessage.removeValue()
                }
            }
            refUserMessage.removeValue()
        })
        
        let refUserMessage2 = Database.database().reference().child(Configuration.environment).child("user-messages").child(account.toId!).child(LocalUserRepository.currentUid)
        refUserMessage2.removeValue()
        
        let anonymousRef = Database.database().reference().child(Configuration.environment).child("anonymous-users").child(account.id!)
        anonymousRef.removeValue()
        
        if let myAccount = LocalUserRepository.shared().loadUserFromCache(uid: LocalUserRepository.currentUid) {
            let endChatRef = Database.database().reference().child(Configuration.environment).child("chat-ended").child(account.toId!)
            endChatRef.updateChildValues([stage : myAccount.name! ])
        } else {
            let ref = Database.database().reference().child(Configuration.environment).child("users").child(LocalUserRepository.currentUid)
            ref.observeSingleEvent(of: .value, with: {(snapshot) in
                if let dictionary = snapshot.value as? [String: AnyObject] {
                    let myAccount = Account()
                    myAccount.id = LocalUserRepository.currentUid
                    myAccount.setValuesForKeys(dictionary)
                    LocalUserRepository.shared().setObject(myAccount)
                    
                    let endChatRef = Database.database().reference().child(Configuration.environment).child("chat-ended").child(account.toId!)
                    endChatRef.updateChildValues([stage : myAccount.name! ])
                }
            })
            
        }
        
        let failedRef  = Database.database().reference().child(Configuration.environment).child("failed-attempt").child(LocalUserRepository.currentUid).child(account.id!)
        failedRef.removeValue()
    }
    
    func endChat(account: Account) {
        let refLastMessage = Database.database().reference().child(Configuration.environment).child("last-user-message").child(LocalUserRepository.currentUid).child(account.id!)
        refLastMessage.removeValue()
        let refLastMessage2 = Database.database().reference().child(Configuration.environment).child("last-user-message").child(account.id!).child(account.toId!)
        refLastMessage2.removeValue()
        let readRef = Database.database().reference().child(Configuration.environment).child("last-user-message-read").child(LocalUserRepository.currentUid).child(account.id!)
        readRef.removeValue()
        let readRef1 = Database.database().reference().child(Configuration.environment).child("last-user-message-read").child(account.id!).child(account.toId!)
        readRef1.removeValue()
        
        let refConnection = Database.database().reference().child(Configuration.environment).child("connections").child(LocalUserRepository.currentUid)
        refConnection.updateChildValues([account.id! : "none"])
        let refUserMessage = Database.database().reference().child(Configuration.environment).child("user-messages").child(LocalUserRepository.currentUid).child(account.id!)
        refUserMessage.observeSingleEvent(of: .value, with: {(snapshot) in
            if let dictionary = snapshot.value as? [String: Int] {
                for map in dictionary {
                    let messageId = map.key
                    let refMessage = Database.database().reference().child(Configuration.environment).child("messages").child(messageId)
                    refMessage.removeValue()
                }
            }
            refUserMessage.removeValue()
        })
        
        let refUserMessage2 = Database.database().reference().child(Configuration.environment).child("user-messages").child(account.id!).child(account.toId!)
        refUserMessage2.removeValue()
        
        let anonymousRef = Database.database().reference().child(Configuration.environment).child("anonymous-users").child(account.toId!)
        anonymousRef.observeSingleEvent(of: .value, with: {(snapshot) in
            if let dictionary = snapshot.value as? [String: String] {
                let endChatRef = Database.database().reference().child(Configuration.environment).child("chat-ended").child(account.id!)
                endChatRef.updateChildValues(["ended" : Array(dictionary)[0].value ])
            }
            anonymousRef.removeValue()
        })
        
        let failedRef  = Database.database().reference().child(Configuration.environment).child("failed-attempt").child(account.id!).child(account.toId!)
        failedRef.removeValue()
    }
    
}

