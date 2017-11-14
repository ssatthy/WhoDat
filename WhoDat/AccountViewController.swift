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
    var pretendingUser: Account?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        navigationItem.title = "Guess a friend"
        
        tableView.register(AccountCell.self, forCellReuseIdentifier: cellId)
        fetchUsers()
    }
    
    func fetchUsers() {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        Database.database().reference().child("connections").child(uid).observe(.childAdded, with:
            {(snapshot) in
                let userId = snapshot.key
                if let account = LocalUserRepository.shared().loadUserFromCache(uid: userId) {
                    self.accounts.append(account)
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                } else {
                    let userRef = Database.database().reference().child("users").child(userId)
                    userRef.observeSingleEvent(of: .value, with: {(snapshot) in
                        if let dictionary = snapshot.value as? [String: AnyObject] {
                            let account = Account()
                            account.id = snapshot.key
                            account.setValuesForKeys(dictionary)
                            LocalUserRepository.shared().setObject(account)
                            
                            self.accounts.append(account)
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                        }
                        
                    })
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
        cell.detailTextLabel?.text = user.email
        
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
            let account = self.accounts[indexPath.row]
            if self.pretendingUser!.representedUserId == account.id {
                guard let uid = Auth.auth().currentUser?.uid else {return}
                
                if self.pretendingUser!.beenCaught {
                    let refBeenCaught = Database.database().reference().child("users-been-caught").child(uid).child(self.pretendingUser!.id!)
                    refBeenCaught.removeValue()
                    let refCaught = Database.database().reference().child("users-caught").child(self.pretendingUser!.representedUserId!).child(self.pretendingUser!.impersonatingUserId!)
                    refCaught.removeValue()
                    let refLastMessage = Database.database().reference().child("last-user-message").child(uid).child(self.pretendingUser!.id!)
                    refLastMessage.removeValue()
                    let refLastMessage2 = Database.database().reference().child("last-user-message").child(account.id!).child(self.pretendingUser!.impersonatingUserId!)
                    refLastMessage2.removeValue()
                    let refConnection = Database.database().reference().child("connections").child(uid)
                    refConnection.updateChildValues([self.pretendingUser!.id! : "none"])
                    let refConnection2 = Database.database().reference().child("connections").child(account.id!)
                    refConnection2.updateChildValues([self.pretendingUser!.impersonatingUserId! : "none"])
                    let refUserMessage = Database.database().reference().child("user-messages").child(uid).child(account.id!)
                    refUserMessage.observeSingleEvent(of: .value, with: {(snapshot) in
                        if let dictionary = snapshot.value as? [String: String] {
                            for map in dictionary {
                                let messageId = map.key
                                let refMessage = Database.database().reference().child("messages").child(messageId)
                                refMessage.removeValue()
                            }
                        }
                        snapshot.ref.removeValue()
                    })
                    
                    let refUserMessage2 = Database.database().reference().child("user-messages").child(account.id!).child(uid)
                    refUserMessage2.removeValue()
                } else {
                    let refCaught = Database.database().reference().child("users-caught").child(uid)
                    refCaught.updateChildValues([self.pretendingUser!.id! : 1])
                    let refBeenCaught = Database.database().reference().child("users-been-caught").child(self.pretendingUser!.representedUserId!)
                    refBeenCaught.updateChildValues([self.pretendingUser!.impersonatingUserId! : 1])
                }
                
            }
            self.handleCancel()
            
        })
    }
    
}

