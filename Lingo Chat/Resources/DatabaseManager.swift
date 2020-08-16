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
        database.child("Users").queryOrdered(byChild: userID).observeSingleEvent(of: .childAdded) { (snapshot) in
            guard snapshot.value as? String != nil else {
                print("user does not exists")
                completion(false)
                return
            }
            print(snapshot.value ?? "no value")
            print("user exists")
            completion(true)
        }
    }
    
    
//    insert methods
    
/// insert new user account user
    public func insertUser(with user: UserAccount) {
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else { return }
        database.child("Users").child(userID).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName,
            "email": user.email,
            "image": user.image,
            "lang": user.language
            ], withCompletionBlock: { error,_ in
                guard error == nil else {
                    return
                }
                
//                fetch users list
                
                self.database.child("Users").observeSingleEvent(of: .value) { (snapshot) in
                    if var usersCollection = snapshot.value as? [[String: String]] {
                        
                    }
                    else {
                        let newCollection: [[String: String]] = [
                        ]
                    }
                }
        })
        
        
        
    }
    
    public func insertPreferences(image: String, language: Int) {
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else { return }
        database.child("Users").child(userID).updateChildValues(["image": image])
        
        database.child("Users").child(userID).updateChildValues(["lang": language])
    }
    

    
//    update methods
    
    
//    deletion methods
    
    
    
    
//    query methods
    
    public func getUserDetails(completion: @escaping (Result<[Any], Error>) -> Void) {
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else { return }
        database.child("Users").child(userID).observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value as? [String: Any] else {
                completion(.failure(DatabaseErrors.failedToFetchData))
                return
            }
            print("Sanapshot", value)
            var returnArray: [Any] = []
            returnArray.append(value["first_name"])
            returnArray.append(value["last_name"])
            returnArray.append(value["image"])
            returnArray.append(value["lang"])
            completion(.success(returnArray))
        }
    }
}

public enum DatabaseErrors: Error {
    case failedToFetchData
}


struct UserAccount {
    let firstName: String
    let lastName: String
    let email: String
    let image: String
    let language: Int
}
