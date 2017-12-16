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
    
    func setNavBar(account: Account) {
        
        let titleBar = UIView()
        titleBar.isUserInteractionEnabled = true
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
        foundIndicator.backgroundColor = UIColor(r: 0, g: 204, b: 0)
        foundIndicator.tag = 111
        
        let beenCaughtIndicator = UIView()
        beenCaughtIndicator.translatesAutoresizingMaskIntoConstraints = false
        beenCaughtIndicator.layer.cornerRadius = 22
        beenCaughtIndicator.layer.masksToBounds = true
        beenCaughtIndicator.backgroundColor = UIColor.red
        beenCaughtIndicator.tag = 222
        
        containerView.addSubview(foundIndicator)
        containerView.addSubview(beenCaughtIndicator)
        
        let profileImageView = UIImageView()
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 20
        profileImageView.clipsToBounds = true
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        if let profileImageUrl = account.profileImageUrl {
            profileImageView.loadImagesFromCache(urlString: profileImageUrl)
        } else {
            profileImageView.image = UIImage(named: "profilepic")
        }
        containerView.addSubview(profileImageView)
        profileImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        
        foundIndicator.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor).isActive = true
        foundIndicator.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        foundIndicator.widthAnchor.constraint(equalToConstant: 44).isActive = true
        foundIndicator.heightAnchor.constraint(equalToConstant: 44).isActive = true
        foundIndicator.isHidden = true
        beenCaughtIndicator.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor).isActive = true
        beenCaughtIndicator.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        beenCaughtIndicator.widthAnchor.constraint(equalToConstant: 44).isActive = true
        beenCaughtIndicator.heightAnchor.constraint(equalToConstant: 44).isActive = true
        beenCaughtIndicator.isHidden = true
        
        let nameLabel = UILabel()
        containerView.addSubview(nameLabel)
        
        nameLabel.text = account.name
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
        nameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        nameLabel.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        self.navigationItem.titleView = titleBar
        
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
