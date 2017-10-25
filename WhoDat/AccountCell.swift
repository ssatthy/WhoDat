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
            setNameAndProfilePicture()
            self.detailTextLabel?.text = self.message?.message
            if let seconds = self.message?.timestamp?.doubleValue {
                let timestampDate = NSDate(timeIntervalSince1970: seconds)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "hh:mm a"
                self.timeLabel.text = dateFormatter.string(from: timestampDate as Date)
            }
            
        }
    }
    
    private func setNameAndProfilePicture() {
        let account = message?.account
        
        self.textLabel?.text = account?.name
        if account?.profileImageUrl != nil {
            self.profileImageView.loadImagesFromCache(urlString: account!.profileImageUrl!)
        } else {
            self.profileImageView.image = UIImage(named: "profilepic")
        }
        
        foundIndicator.backgroundColor = UIColor.white
        setAttention(account: account!)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        setTextLabelXY(x: 64)
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
        
        addSubview(foundIndicator)
        addSubview(profileImageView)
        
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 48).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 48).isActive = true

        foundIndicator.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor).isActive = true
        foundIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        foundIndicator.widthAnchor.constraint(equalToConstant: 52).isActive = true
        foundIndicator.heightAnchor.constraint(equalToConstant: 52).isActive = true
        
        addSubview(timeLabel)
        
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        timeLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 12).isActive = true
        timeLabel.widthAnchor.constraint(equalToConstant: 80).isActive = true
        timeLabel.heightAnchor.constraint(equalTo: textLabel!.heightAnchor).isActive = true
        
    }
    
    private func setAttention(account: Account) {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        let refCaught = Database.database().reference().child("users-caught").child(uid).queryOrderedByKey()
            .queryEqual(toValue: account.id!)
        refCaught.observe(.childAdded, with: {(snapshot) in
            self.foundIndicator.backgroundColor = UIColor(r: 61, g: 151, b: 61)
        })
        
        let refBeenCaught = Database.database().reference().child("users-caught").child(account.representedUserId!).queryOrderedByKey().queryEqual(toValue: uid)
        refBeenCaught.observe(.childAdded, with: {(snapshot) in
            self.foundIndicator.backgroundColor = UIColor(r: 151, g: 61, b: 61)
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
