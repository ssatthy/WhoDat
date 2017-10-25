//
//  MessageCell.swift
//  WhoDat
//
//  Created by Sathy on 10/16/17.
//  Copyright © 2017 LTAC. All rights reserved.
//

import UIKit

class MessageCell: UICollectionViewCell {
    
    let textView: UITextView = {
        let textView = UITextView()
        textView.text = "Sample message goes here"
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.backgroundColor = UIColor.clear
        textView.textColor = UIColor.white
        return textView
    }()
    
    static let blueColor = UIColor(r: 0, g: 137, b: 249)
    static let grayColor = UIColor(r: 240, g: 240, b: 240)
    
    let bubbleView: UIView = {
        let bubbleView = UIView()
        bubbleView.backgroundColor = blueColor
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.layer.cornerRadius = 16
        bubbleView.layer.masksToBounds = true
        
        return bubbleView
    }()
    
    let bubbleProfile: UIImageView = {
        let profile = UIImageView()
        profile.image = UIImage(named: "profilepic")
        profile.layer.cornerRadius = 16
        profile.layer.masksToBounds = true
        profile.contentMode = .scaleAspectFill
        return profile
    }()
    
    var bubbleWidthAnchor: NSLayoutConstraint?
    var bubbleRightAnchor: NSLayoutConstraint?
    var bubbleLeftAnchor:NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(bubbleView)
        addSubview(textView)
        addSubview(bubbleProfile)
        
        bubbleProfile.translatesAutoresizingMaskIntoConstraints = false
        bubbleProfile.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        bubbleProfile.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        bubbleProfile.widthAnchor.constraint(equalToConstant: 32).isActive = true
        bubbleProfile.heightAnchor.constraint(equalToConstant: 32).isActive = true
        
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        bubbleRightAnchor = bubbleView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8)
        
        bubbleLeftAnchor = bubbleView.leftAnchor.constraint(equalTo: bubbleProfile.rightAnchor, constant: 8)
        
        
        bubbleRightAnchor?.isActive = true
        bubbleView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        bubbleWidthAnchor = bubbleView.widthAnchor.constraint(equalToConstant: 200)
        bubbleWidthAnchor?.isActive = true
        bubbleView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 8).isActive = true
        textView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        textView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor).isActive = true
        textView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
