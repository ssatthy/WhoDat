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
    
    var id: String?
    var fromId: String?
    var toId: String?
    var timestamp: NSNumber?
    var message: String?
    
    var account: Account?
}
