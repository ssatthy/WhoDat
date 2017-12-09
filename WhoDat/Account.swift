//
//  User.swift
//  WhoDat
//
//  Created by Sathyavarathan Sivabalasingam on 10/14/17.
//  Copyright © 2017 LTAC. All rights reserved.
//

import UIKit

@objcMembers class Account: NSObject {

    var id: String?
    var name: String?
    var phone: String?
    var profileImageUrl: String?
    var token: String?

    var representedUserId: String?
    
    var impersonatingUserId: String?
    
}
