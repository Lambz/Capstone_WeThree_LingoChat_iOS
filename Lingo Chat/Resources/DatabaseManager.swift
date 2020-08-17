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
            ])
     }
    
    
    

    
//    update methods
    
    
    public func insertPreferences(image: String, language: String) {
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else { return }
        database.child("Users").child(userID).updateChildValues(["image": image])
        
        database.child("Users").child(userID).updateChildValues(["lang": language])
    }
    
    
    public func updateProfile(firstName: String, lastName: String) {
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else { return }
        database.child("Users").child(userID).updateChildValues(["first_name": firstName])
        
        database.child("Users").child(userID).updateChildValues(["last_name": lastName])
    }
    
    public func updateLanguage(language: String) {
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else { return }
        database.child("Users").child(userID).updateChildValues(["lang": language])
    }
    
    public func updateImageUrl(image: String) {
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else { return }
        database.child("Users").child(userID).updateChildValues(["image": image])
    }
    
//    deletion methods
    
    
    
    
//    query methods
    
    public func getUserDetails(completion: @escaping (Result<[String], Error>) -> Void) {
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else { return }
        database.child("Users").child(userID).observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value as? [String: String] else {
                completion(.failure(DatabaseErrors.failedToFetchData))
                return
            }
//            print("Snapshot", value)
            var returnArray: [String] = []
            returnArray.append(value["first_name"] ?? "")
            returnArray.append(value["last_name"] ?? "")
            returnArray.append(value["image"] ?? "")
            returnArray.append(value["lang"] ?? "")
            completion(.success(returnArray))
        }
    }
    
    public func fetchAllUsers(completion: @escaping (Result<[UserAccount], Error>) -> Void) {
        let userEmail = FirebaseAuth.Auth.auth().currentUser?.email?.lowercased()
        database.child("Users").observeSingleEvent(of: .value) { (snapshot) in
            var users = [UserAccount]()
            for case let child as DataSnapshot in snapshot.children {
                guard let item = child.value as? [String:String] else {
                    print("Error")
                    completion(.failure(DatabaseErrors.failedToFetchData))
                    return
                }
                if item["email"]!.lowercased() == userEmail {
                    continue
                }
                let user = UserAccount(firstName: item["first_name"]!, lastName: item["last_name"]!, email: item["email"]!, image: item["image"]!, language: item["lang"]!)
//                print(user)
                users.append(user)
            }
            completion(.success(users))
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
    let language: String
}
