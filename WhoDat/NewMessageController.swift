//
//  NewMessageController.swift
//  WhoDat
//
//  Created by Sathyavarathan Sivabalasingam on 10/14/17.
//  Copyright © 2017 LTAC. All rights reserved.
//

import UIKit
import Firebase
import Contacts
import ContactsUI

class NewMessageController: UITableViewController, CNContactPickerDelegate , InviteDelegate  {

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

        Database.database().reference().child(Configuration.environment).child("connections").child(uid).observe(.childAdded, with:
            {(snapshot) in
                let userId = snapshot.key
                let representedValue = snapshot.value
                
                // intentionally not using cache here, because have ample time here to load user data and help to refresh user details
                let userRef = Database.database().reference().child(Configuration.environment).child("users").child(userId)
                userRef.observeSingleEvent(of: .value, with: {(snapshot) in
                    if let dictionary = snapshot.value as? [String: AnyObject] {
                        let account = Account()
                        account.id = snapshot.key
                        account.setValuesForKeys(dictionary)
                        LocalUserRepository.shared().setObject(account)
                        
                        if let dictionary = representedValue as? [String: String] {
                            let map = Array(dictionary)[0]
                            account.representedUserId = map.key
                            account.impersonatingUserId = map.value
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
    
    @objc func handleAdd() {
        let type = CNEntityType.contacts
        let status = CNContactStore.authorizationStatus(for: type)
        if status == CNAuthorizationStatus.authorized {
            presentContacts()
        } else if status == CNAuthorizationStatus.notDetermined {
            let store = CNContactStore.init()
            store.requestAccess(for: type, completionHandler: {(success, nil) in
                if success {
                    self.presentContacts()
                }
            })
        }
    }
    
    func presentContacts() {
        let picker = CNContactPickerViewController.init()
        picker.predicateForSelectionOfContact = NSPredicate(format: "phoneNumbers.@count > 0")
        picker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }
    
    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contactProperty: CNContactProperty) {
        addNewConnection(contactProperty)
    }
    
    func addNewConnection(_ contactProperty: CNContactProperty) {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        let phone  = (contactProperty.value as? CNPhoneNumber)?.value(forKey: "digits")
        let userRef = Database.database().reference().child(Configuration.environment).child("users").queryOrdered(byChild: "phone").queryEqual(toValue: phone)
        userRef.observeSingleEvent(of: .value, with: {(snapshot) in
            print("check if phone exists")
            print(snapshot)
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let userId = Array(dictionary)[0].key
                let connectionRef = Database.database().reference().child(Configuration.environment).child("connections").child(uid)
                connectionRef.updateChildValues([userId : "none"])
                let connectionOtherRef = Database.database().reference().child(Configuration.environment).child("connections").child(userId)
                connectionOtherRef.updateChildValues([uid : "none"])
            } else {
                print(contactProperty.contact.givenName)
                let alert = UIAlertController(title: "Invite \(contactProperty.contact.givenName)", message: "You friend is not on WhoDat. Would you like to invite?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
                alert.addAction(UIAlertAction(title: "Invite", style: .default, handler: {(_) in
                    let objectsToShare = ["Hey \(contactProperty.contact.givenName)!, just try this one out!"]
                    let activityController = UIActivityViewController(
                        activityItems: objectsToShare,
                        applicationActivities: nil)
                    activityController.popoverPresentationController?.sourceRect = self.view.frame
                    activityController.popoverPresentationController?.sourceView = self.view
                    activityController.popoverPresentationController?.permittedArrowDirections = .any
                    self.present(activityController, animated: true, completion: nil)
                }))
                self.present(alert, animated: true, completion: nil)
            }
            
        })
    }
    
    var messageController: MessageController?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true, completion: {
            let account = self.accounts[indexPath.row]
            self.messageController?.showChatLogController(selectedAccount: account, accounts: self.accounts)
        })
    }

}

