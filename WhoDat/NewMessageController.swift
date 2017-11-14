//
//  NewMessageController.swift
//  WhoDat
//
//  Created by Sathyavarathan Sivabalasingam on 10/14/17.
//  Copyright © 2017 LTAC. All rights reserved.
//

import UIKit
import Firebase

class NewMessageController: UITableViewController {

    let cellId = "cellId"
    var accounts = [Account]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        navigationItem.title = "Select a friend"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(handleAdd))

        tableView.register(AccountCell.self, forCellReuseIdentifier: cellId)
        fetchUsers()
    }

    func fetchUsers() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }

        Database.database().reference().child("connections").child(uid).observe(.childAdded, with:
            {(snapshot) in
                let userId = snapshot.key
                let representedValue = snapshot.value
                
                // intentionally not using cache here, because have ample time here to load user data and help to refresh user details
                let userRef = Database.database().reference().child("users").child(userId)
                userRef.observeSingleEvent(of: .value, with: {(snapshot) in
                    if let dictionary = snapshot.value as? [String: AnyObject] {
                        let account = Account()
                        account.id = snapshot.key
                        account.setValuesForKeys(dictionary)
                        LocalUserRepository.shared().setObject(account)
                        
                        if let representedUserId = representedValue as? String, representedUserId != "none" {
                            account.representedUserId = representedUserId
                            self.setImpersonatingUserId(representedUserId: representedUserId, account: account)
                        }
                        
                        self.accounts.append(account)
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                
                })
                
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
    
    @objc func handleAdd() {
        let alert = UIAlertController(title: "Add a friend", message: "Enter your friend's email", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: {(_) in }))
        
        let saveAction = UIAlertAction(title: "Add", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]
            let email = textField?.text
            
            self.addNewConnection(email!)
            
        })
        saveAction.isEnabled = false
        alert.addAction(saveAction)
        alert.addTextField { (textField) in
            textField.placeholder = "Email address"
            NotificationCenter.default.addObserver(forName: NSNotification.Name.UITextFieldTextDidChange, object: textField, queue: OperationQueue.main) { (notification) in
                saveAction.isEnabled = self.isValidEmail(testStr: textField.text!)
            }
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    func addNewConnection(_ email: String) {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        let userRef = Database.database().reference().child("users").queryOrdered(byChild: "email").queryEqual(toValue: email)
        userRef.observe(.childAdded, with: {(snapshot) in
            
            let userId = snapshot.key
            let connectionRef = Database.database().reference().child("connections").child(uid)
            connectionRef.updateChildValues([userId : "none"])
                
            let connectionOtherRef = Database.database().reference().child("connections").child(userId)
            connectionOtherRef.updateChildValues([uid : "none"])

            return
        })
        
        print("User not found!") // send invitation
    }
    
    var messageController: MessageController?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true, completion: {
            let account = self.accounts[indexPath.row]
            self.messageController?.showChatLogController(selectedAccount: account, accounts: self.accounts)
        })
    }

}

