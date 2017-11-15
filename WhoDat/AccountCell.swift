//
//  AccountCell.swift
//  WhoDat
//
//  Created by Sathyavarathan Sivabalasingam on 10/15/17.
//  Copyright © 2017 LTAC. All rights reserved.
//

import UIKit
import Firebase

class AccountCell: UITableViewCell {
    
    var message: Message? {
        didSet {
            setNameAndProfilePicture(account: message!.account!)
            self.detailTextLabel?.text = self.message?.message
            if let seconds = self.message?.timestamp?.doubleValue {
                let timestampDate = NSDate(timeIntervalSince1970: seconds)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "hh:mm a"
                self.timeLabel.text = dateFormatter.string(from: timestampDate as Date)
            }
            if oldValue == nil {
                setupAttention(account: message!.account!)
                setupUnread()
            }
        }
    }
    
    private func setNameAndProfilePicture(account: Account) {
        self.textLabel?.text = account.name
        if account.profileImageUrl != nil {
            self.profileImageView.loadImagesFromCache(urlString: account.profileImageUrl!)
        } else {
            self.profileImageView.image = UIImage(named: "profilepic")
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        setTextLabelXY(x: 74)
    }
    
    private func setTextLabelXY(x: CGFloat) {
        textLabel?.frame = CGRect(x: x, y: textLabel!.frame.origin.y - 2, width:  textLabel!.frame.width, height:  textLabel!.frame.height)
        detailTextLabel?.frame = CGRect(x: x, y: detailTextLabel!.frame.origin.y + 2, width:  self.frame.width - 80, height:  detailTextLabel!.frame.height)
    }
    
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "profilepic")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 24
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    let foundIndicator: UIView = {
        let indicator = UIView()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.layer.cornerRadius = 26
        indicator.layer.masksToBounds = true
        indicator.backgroundColor = UIColor(r: 0, g: 204, b: 0)
        indicator.isHidden = true
        return indicator
    }()
    
    let beenCaughtIndicator: UIView = {
        let indicator = UIView()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.layer.cornerRadius = 26
        indicator.layer.masksToBounds = true
        indicator.backgroundColor = UIColor.red
        indicator.isHidden = true
        return indicator
    }()
    
    let unread: UIView = {
        let indicator = UIView()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.layer.cornerRadius = 5
        indicator.layer.masksToBounds = true
        indicator.backgroundColor = UIColor(r: 0, g: 102, b: 204)
        indicator.isHidden = true
        return indicator
    }()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = UIColor.darkGray
        return label
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        addSubview(unread)
        addSubview(foundIndicator)
        addSubview(beenCaughtIndicator)
        addSubview(profileImageView)
        
        unread.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 4).isActive = true
        unread.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        unread.widthAnchor.constraint(equalToConstant: 10).isActive = true
        unread.heightAnchor.constraint(equalToConstant: 10).isActive = true
        
        profileImageView.leftAnchor.constraint(equalTo: unread.leftAnchor, constant: 16).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 48).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        foundIndicator.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor).isActive = true
        foundIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        foundIndicator.widthAnchor.constraint(equalToConstant: 52).isActive = true
        foundIndicator.heightAnchor.constraint(equalToConstant: 52).isActive = true
        
        beenCaughtIndicator.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor).isActive = true
        beenCaughtIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        beenCaughtIndicator.widthAnchor.constraint(equalToConstant: 52).isActive = true
        beenCaughtIndicator.heightAnchor.constraint(equalToConstant: 52).isActive = true
        
        addSubview(timeLabel)
        
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        timeLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 12).isActive = true
        timeLabel.widthAnchor.constraint(equalToConstant: 80).isActive = true
        timeLabel.heightAnchor.constraint(equalTo: textLabel!.heightAnchor).isActive = true
        
    }
    
    private func setupAttention(account: Account) {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let refCaught = Database.database().reference().child("users-caught").child(uid).queryOrderedByKey()
            .queryEqual(toValue: account.id!)
        refCaught.observe(.value, with: {(snapshot) in
            print("found")
            print(snapshot)
            if let _ = snapshot.value as? [String: Int] {
                self.foundIndicator.isHidden = false
            } else {
                self.foundIndicator.isHidden = true
            }
        })
        
        let refBeenCaught = Database.database().reference().child("users-been-caught").child(uid).queryOrderedByKey().queryEqual(toValue: account.id!)
        refBeenCaught.observe(.value, with: {(snapshot) in
            print("caught")
            print(snapshot)
            if let _ = snapshot.value as? [String: Int] {
                self.beenCaughtIndicator.isHidden = false
            } else {
                self.beenCaughtIndicator.isHidden = true
            }
            
        })
    }
    
    func setupUnread() {
        unread.isHidden = true
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let ref = Database.database().reference().child("last-user-message-read").child(uid).child(message!.account!.id!)
        ref.observe(.value, with: {(snapshot) in
            print("read observed")
            print(snapshot)
            if let read = snapshot.value as? Int, read == 1 {
                self.unread.isHidden = false
            } else {
                self.unread.isHidden = true
            }
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
