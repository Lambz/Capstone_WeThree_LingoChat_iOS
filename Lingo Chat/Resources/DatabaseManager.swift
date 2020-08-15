//
//  DatabaseManager.swift
//  Lingo Chat
//
//  Created by Chetan on 2020-08-11.
//  Copyright © 2020 Chetan. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth

final class DatabaseManager {
    static let shared = DatabaseManager()
    private let database = Database.database().reference()    
}

//MARK: Transcation menthods implemented

extension DatabaseManager {
    
//    verification methods for account creation
    
///   verifies weather user account with same email exists
    public func userAccountExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else { return }
        database.child("Users").child(userID).queryOrdered(byChild: "email").observeSingleEvent(of: .value) { (snapshot) in
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
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else { return }
        database.child("Users").child(userID).setValue([
            "first-name": user.firstName,
            "last-name": user.lastName,
            "email": user.email
        ])
    }
    
    public func insertPreferences(image: String, language: Int) {
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else { return }
        let imgChild = database.child("Users").child(userID).child("image")
        imgChild.setValue(image)
        let langChild = database.child("Users").child(userID).child("lang")
        langChild.setValue(language)
    }
    

    
//    update methods
    
    
//    deletion methods
}


struct UserAccount {
    let firstName: String
    let lastName: String
    let email: String
//    let profilePicUrl: String
//    let userLanguage: Int
}
