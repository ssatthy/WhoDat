//
//  Message.swift
//  WhoDat
//
//  Created by Sathyavarathan Sivabalasingam on 10/15/17.
//  Copyright © 2017 LTAC. All rights reserved.
//

import UIKit
import Firebase

@objcMembers class Message: NSObject {
    
    var fromId: String?
    var toId: String?
    var timestamp: NSNumber?
    var message: String?
    
    func representedUserId() -> String? {
        return fromId == Auth.auth().currentUser?.uid ? toId : fromId
    }
    
    var pretendingUserId: String?
    var account: Account?
}
