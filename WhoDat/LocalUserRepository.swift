//
//  LocalUserRepository.swift
//  WhoDat
//
//  Created by Sathy on 11/12/17.
//  Copyright © 2017 LTAC. All rights reserved.
//

import Foundation

class LocalUserRepository {
    
    private static let localUserRepository =  LocalUserRepository()
    
    private init() { }
    
    class func shared() -> LocalUserRepository {
        return localUserRepository
    }
    
    var userCache = NSCache<AnyObject, AnyObject>()
    
    func loadUserFromCache(uid: String) -> Account? {
        if let account = userCache.object(forKey: uid as AnyObject) {
            return account as? Account
        }
        return nil
    }
    
    func setObject(_ account: Account) {
        userCache.setObject(account, forKey: account.id as AnyObject)
    }
    
    func reset() {
        userCache = NSCache<AnyObject, AnyObject>()
    }
}
