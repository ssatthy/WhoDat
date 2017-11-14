//
//  Extensions.swift
//  WhoDat
//
//  Created by Sathyavarathan Sivabalasingam on 10/15/17.
//  Copyright © 2017 LTAC. All rights reserved.
//

import UIKit
import Firebase

let imageCache = NSCache<AnyObject, AnyObject>()

extension UIImageView {
    
    func loadImagesFromCache(urlString: String) {
        
        self.image = nil
        
        if let cachedImage = imageCache.object(forKey: urlString as AnyObject) {
            self.image = cachedImage as? UIImage
            return
        }
        
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!, completionHandler: {(data, response, error) in
            
            if error != nil {
                print(error ?? "Error while downloading profile picture!")
                return
            }
            
            DispatchQueue.main.async {
                if let downloadedImage = UIImage(data: data!) {
                    imageCache.setObject(downloadedImage, forKey: urlString as AnyObject)
                    self.image = downloadedImage
                }
            }
            
        }).resume()
    }
}


extension UIViewController {
    
    func setImpersonatingUserId(representedUserId: String, account: Account) {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = Database.database().reference().child("connections").child(representedUserId).queryOrderedByValue().queryEqual(toValue: uid)
        ref.observe(.childAdded, with: {(snapshot) in
            account.impersonatingUserId = snapshot.key
        })
        
    }
    
    
    func setNavBar(account: Account) {
        
        let titleBar = UIView()
        titleBar.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        
        let containerView = UIView()
        titleBar.addSubview(containerView)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.centerXAnchor.constraint(equalTo: titleBar.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: titleBar.centerYAnchor).isActive = true
        
        let foundIndicator = UIView()
        foundIndicator.translatesAutoresizingMaskIntoConstraints = false
        foundIndicator.layer.cornerRadius = 22
        foundIndicator.layer.masksToBounds = true
        foundIndicator.tag = 111
        
        containerView.addSubview(foundIndicator)
        
        let profileImageView = UIImageView()
        containerView.addSubview(profileImageView)
        
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 20
        profileImageView.clipsToBounds = true
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.tag = 222
        if let profileImageUrl = account.profileImageUrl {
            profileImageView.loadImagesFromCache(urlString: profileImageUrl)
        } else {
            profileImageView.image = UIImage(named: "profilepic")
        }
        
        profileImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        
        foundIndicator.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor).isActive = true
        foundIndicator.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        foundIndicator.widthAnchor.constraint(equalToConstant: 44).isActive = true
        foundIndicator.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        
        let nameLabel = UILabel()
        containerView.addSubview(nameLabel)
        
        nameLabel.text = account.name
        nameLabel.tag = 333
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
        nameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        nameLabel.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        self.navigationItem.titleView = titleBar
        
    }
    
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
