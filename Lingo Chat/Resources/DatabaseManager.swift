//
//  DatabaseManager.swift
//  Lingo Chat
//
//  Created by Chetan on 2020-08-11.
//  Copyright © 2020 Chetan. All rights reserved.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    static let shared = DatabaseManager()
    private let database = Database.database().reference()    
}

//MARK: Transcation menthods implemented

extension DatabaseManager {
    
//    verification methods for account creation
    
///   verifies weather user account with same email exists
    public func userAccountExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        let safeEmail = email.replacingOccurrences(of: ".", with: "-").replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value) { (snapshot) in
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    
//    insert methods
    
/// insert new user account user
    public func insertUser(with user: UserAccount) {
        database.child(user.safeEmail).setValue([
            "first-name": user.firstName,
            "last-name": user.lastName,
//            "email": user.email
        ])
    }
    
    
//    update methods
    
    
//    deletion methods
}


struct UserAccount {
    let firstName: String
    let lastName: String
    let email: String
    var safeEmail: String {
        let safeEmail = email.replacingOccurrences(of: ".", with: "-").replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
//    let profilePicUrl: URL
//    let userLanguage: String
}
