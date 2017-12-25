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

class NewMessageController: UITableViewController, InviteDelegate  {

    let cellId = "cellId"
    var accounts = [Account]()
    let contactStore = CNContactStore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        navigationItem.title = "Select a friend"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Invite", style: .plain, target: self, action: #selector(handleInvite))

        tableView.register(AccountCell.self, forCellReuseIdentifier: cellId)
        fetchAndFilterUsers()
        askContactPermission()
    }
    
    func askContactPermission() {
        let type = CNEntityType.contacts
        let status = CNContactStore.authorizationStatus(for: type)
        if status == CNAuthorizationStatus.authorized {
            autoscanConnections()
        } else if status == CNAuthorizationStatus.notDetermined {
            let store = CNContactStore.init()
            store.requestAccess(for: type, completionHandler: {(success, nil) in
                if success {
                   self.autoscanConnections()
                }
            })
        } else if status == CNAuthorizationStatus.denied {
            showContactDeniedMessage()
        }
    }
    
    func autoscanConnections() {
        let keys = [CNContactPhoneNumbersKey]
        let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
        do {
            try self.contactStore.enumerateContacts(with: request) {
                (contact, stop) in
                for phoneNumber in contact.phoneNumbers {
                    var number = phoneNumber.value.value(forKey: "digits") as! String
                    let code = phoneNumber.value.value(forKey: "countryCode") as! String
                    if !number.starts(with: "+"), let phoneCode =  LocalUserRepository.shared().getPhoneCode(countryCode: code) {
                        number = phoneCode + number
                    }
                    
                    let userRef = Database.database().reference().child(Configuration.environment).child("phones").child(number)
                    userRef.observeSingleEvent(of: .value, with: {(snapshot) in
                        if let userId = snapshot.value as? String {
                            print("phone exists: \(number)")
                            print(snapshot)
                            if userId == LocalUserRepository.currentUid {return}
                            
                            let connectionRef = Database.database().reference().child(Configuration.environment).child("connections").child(LocalUserRepository.currentUid)
                            connectionRef.updateChildValues([userId : "none"])
                            let connectionOtherRef = Database.database().reference().child(Configuration.environment).child("connections").child(userId)
                            connectionOtherRef.updateChildValues([LocalUserRepository.currentUid : "none"])
                        }
                    })
                    
                }
            }
        }
        catch {
            print("unable to fetch contacts \(error)")
        }
    }
    
    var blockedUserIds = Array<String>()
    
    func fetchAndFilterUsers() {
        Database.database().reference().child(Configuration.environment).child("blocked-users").child(LocalUserRepository.currentUid).observeSingleEvent(of: .value, with: {(snapshot) in
            if let dictionary = snapshot.value as? [String : String] {
                self.blockedUserIds = Array(dictionary.keys)
            }
            self.fetchUsers()
        })
    }
    
    func fetchUsers() {
        Database.database().reference().child(Configuration.environment).child("connections").child(LocalUserRepository.currentUid).observe(.childAdded, with:
            {(snapshot) in
                let userId = snapshot.key
                if self.blockedUserIds.contains(userId) {return}
                
                let toId = snapshot.value as! String
                
                // intentionally not using cache here, because have ample time here to load user data and help to refresh user details
                let userRef = Database.database().reference().child(Configuration.environment).child("users").child(userId)
                userRef.observeSingleEvent(of: .value, with: {(snapshot) in
                    if let dictionary = snapshot.value as? [String: AnyObject] {
                        let account = Account()
                        account.id = userId
                        account.setValuesForKeys(dictionary)
                        account.toId = toId
                        
                        LocalUserRepository.shared().setObject(account)
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
    
    @objc func handleInvite() {
        let objectsToShare = ["Hey there!, just try this one out! https://itunes.apple.com/us/app/whodat-anonymous-until-not/id1323692195?ls=1&mt=8"]
        let activityController = UIActivityViewController(
            activityItems: objectsToShare,
            applicationActivities: nil)
        activityController.popoverPresentationController?.sourceRect = self.view.frame
        activityController.popoverPresentationController?.sourceView = self.view
        activityController.popoverPresentationController?.permittedArrowDirections = .any
        self.present(activityController, animated: true, completion: nil)
    }
    
    var messageController: MessageController?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true, completion: {
            let account = self.accounts[indexPath.row]
            self.messageController?.showChatLogController(selectedAccount: account)
        })
    }
    
    func showContactDeniedMessage() {
        
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.minX + 50, y: self.view.frame.size.height/2, width: self.view.frame.size.width - 100 , height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
        toastLabel.text = "Access to contact denied."
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }

}

