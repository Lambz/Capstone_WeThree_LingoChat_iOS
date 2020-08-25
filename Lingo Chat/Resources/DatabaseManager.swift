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
import SwiftGoogleTranslate
import CoreLocation

struct ChatListData {
    let name: String
    let id: String
    let image: String
    let email: String
    let language: String
}


final class DatabaseManager {
    let langCodes = ["0":"en",
                     "1":"fr",
                     "2":"de",
                     "3":"es",
                     "4":"hi"]
    static let shared = DatabaseManager()
    private let database = Database.database().reference()
    public static let dateformatter: DateFormatter = {
        let dateformatter = DateFormatter()
        dateformatter.dateStyle = .medium
        dateformatter.timeStyle = .long
        dateformatter.locale = .current
        return dateformatter
    }()
}

//MARK: Transcation menthods for user details (login/logut/user data) implemented

extension DatabaseManager {
    
    //    verification methods for account creation
    
    ///   verifies weather user account with same email exists
    public func userAccountExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else { return }
        let ref = database.child("Users").child(userID)
        ref.observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                completion(true)
            }
            else {
                completion(false)
            }
        }
        //        database.child("Users").queryOrdered(byChild: userID).observeSingleEvent(of: .childAdded) { (snapshot) in
        //            guard snapshot.value as? String != nil else {
        //                print("user does not exists")
        //                completion(false)
        //                return
        //            }
        //            print(snapshot.value ?? "no value")
        //            print("user exists")
        //            completion(true)
        //        }
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
            var returnArray: [String] = []
            returnArray.append(value["first_name"] ?? "")
            returnArray.append(value["last_name"] ?? "")
            returnArray.append(value["image"] ?? "")
            returnArray.append(value["lang"] ?? "")
            returnArray.append(userID)
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
                users.append(user)
            }
            completion(.success(users))
        }
    }
    
}

//MARK: Message methods implemeted
extension DatabaseManager {
    
    public func generateRandomId() -> String {
        return database.childByAutoId().key!
    }
    
    public func sendMesage(to otherUser: String, message: Message, randomID: String, completion: @escaping (Bool) -> Void) {
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        var link = "", text = "", lat = "", lng = ""
        switch message.kind {
        case .text(let message):
            text = message
        case .photo(let media):
            if let url = media.url?.absoluteString {
                link = url
            }
        case .video(_):
            break
        case .location(let location):
            lat = "\(location.location.coordinate.latitude)"
            lng = "\(location.location.coordinate.longitude)"
        default: break
        }
        //        let randomID = database.childByAutoId().key!
        database.child("Messages").child(userID).child(otherUser).child(randomID).setValue([
            "from": userID,
            "id": randomID,
            "lat": lat,
            "lng": lng,
            "lang": UserDefaults.standard.object(forKey: "language") as! String,
            "link": link,
            "text": text,
            "to": otherUser,
            "type": message.kind.messageKindString
            ], withCompletionBlock: { [weak self] error, _ in
                guard let strongSelf = self, error == nil else {
                    completion(false)
                    return
                }
                strongSelf.database.child("Messages").child(otherUser).child(userID).child(randomID).setValue([
                    "from": userID,
                    "id": randomID,
                    "lat": lat,
                    "lng": lng,
                    "lang": UserDefaults.standard.object(forKey: "language") as! String,
                    "link": link,
                    "text": text,
                    "to": otherUser,
                    "type": message.kind.messageKindString
                    ], withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                })
        })
    }
    
    
    //    query methods
    public func getUserIdFromEmail(email: String, completion: @escaping (Result<String, Error>) -> Void) {
        database.child("Users").queryOrdered(byChild: "email").queryEqual(toValue: email).observeSingleEvent(of: .childAdded) { (snapshot) in
            completion(.success(snapshot.key))
        }
    }
    
    public func checkIfAnyConversation(completion: @escaping(Bool) -> Void) {
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        let ref = database.child("Messages").child(userID)
        ref.observe(.value) { (snapshot) in
            if snapshot.exists() {
                completion(true)
            }
            else {
                completion(false)
            }
        }
    }
    
    public func getAllConversations(completion: @escaping(Result<[ChatListData], Error>) -> Void) {
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else {
            completion(.failure(DatabaseErrors.failedToFetchData))
            return
        }
        var users = [String]()
        
        database.child("Messages").child(userID).observeSingleEvent(of:.value) { [weak self](snapshot) in
            for case let otherUser as DataSnapshot in snapshot.children {
                users.append(otherUser.key)
            }
            if !users.isEmpty {
                self?.getUserDetailsFromId(users: users, completion: { (result) in
                    switch result {
                    case .success(let list):
                        completion(.success(list))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                })
            }
            else {
                print("still empty")
                completion(.success([ChatListData]()))
            }
        }
    }
    
    private func getUserDetailsFromId(users: [String], completion: @escaping(Result<[ChatListData], Error>) -> Void) {
        database.child("Users").observeSingleEvent(of: .value) { (snapshot) in
            var returnArray = [ChatListData]()
            for case let otherUser as DataSnapshot in snapshot.children {
                if users.contains(otherUser.key) {
                    guard let item = otherUser.value as? [String:String] else {
                        print("Error")
                        completion(.failure(DatabaseErrors.failedToFetchData))
                        return
                    }
                    
                    let name = item["first_name"]! + " " + item["last_name"]!
                    let chat = ChatListData(name: name, id: otherUser.key, image: item["image"]!, email: item["email"]!, language: item["lang"]!)
                    returnArray.append(chat)
                }
                
            }
            completion(.success(returnArray))
        }
    }
    
    public func getLastMessage(with user: String, completion: @escaping(Result<String, Error>) -> Void) {
        let dispatchGroup = DispatchGroup()
        SwiftGoogleTranslate.shared.start(with: "AIzaSyCXYq1aabFAVJsxxF-ksC_1cl5oqsW0ZcE")
        let userLang = UserDefaults.standard.object(forKey: "language") as! String
        
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else {
            completion(.failure(DatabaseErrors.failedToFetchData))
            return
        }
        database.child("Messages").child(userID).child(user).queryLimited(toLast: 1).observe(.childAdded, with: { [weak self] (msg) in
            guard let strongSelf = self else {
                completion(.failure(DatabaseErrors.referenceError))
                return
            }
            guard let message = msg.value as? [String: String] else {
                completion(.failure(DatabaseErrors.failedToFetchData))
                return
            }
            
            switch(message["type"]) {
            case "text":
                var lastText = message["text"]!
                dispatchGroup.enter()
                SwiftGoogleTranslate.shared.translate(message["text"]!, strongSelf.langCodes[userLang]!, strongSelf.langCodes[message["lang"]!]!) { (text, error) in
                    
                    if let t = text {
                        lastText = t
                    }
                    dispatchGroup.leave()
                }
                dispatchGroup.notify(queue: DispatchQueue.main) {
                    completion(.success(lastText))
                }
                
            case "image":
                completion(.success(NSLocalizedString("Image", comment: "")))
                
            case "video":
                completion(.success(NSLocalizedString("Video", comment: "")))
                
            case "location":
                completion(.success(NSLocalizedString("Location", comment: "")))
                
            default: completion(.failure(DatabaseErrors.failedToFetchData))
                
            }
        })
    }
    
    public func checkIfMessageExists(user: String, otherUser: String, completion: @escaping(Bool) -> Void) {
        let ref = database.child("Messages").child(user).child(otherUser)
        ref.observe(.value) { (snapshot) in
            if snapshot.exists() {
                completion(true)
            }
            else {
                completion(false)
            }
        }
    }
    
    public func fetchImageUrlFromId(id: String, completion: @escaping(Result<String, Error>) -> Void) {
        database.child("Users").child(id).observeSingleEvent(of: .value) { (snapshot) in
            guard let values = snapshot.value as? [String:String] else {
                completion(.failure(DatabaseErrors.failedToFetchData))
                return
            }
            if let url = values["image"] {
                completion(.success(url))
            }
            else {
                completion(.failure(DatabaseErrors.failedToFetchData))
            }
        }
    }
    
    public func getAllMessagesForConversation(user: Sender, with: Sender, completion: @escaping(Result<[Message], Error>) -> Void) {
        var msgs = [Message]()
        let dispatchGroup = DispatchGroup()
        SwiftGoogleTranslate.shared.start(with: "AIzaSyCXYq1aabFAVJsxxF-ksC_1cl5oqsW0ZcE")
        let userLang = UserDefaults.standard.object(forKey: "language") as! String
        
        database.child("Messages").child(user.senderId).child(with.senderId).observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard let strongSelf = self else {
                completion(.failure(DatabaseErrors.referenceError))
                return
            }
            for case let message as DataSnapshot in snapshot.children {
                guard let item = message.value as? [String: String] else {
                    completion(.failure(DatabaseErrors.failedToFetchData))
                    return
                }
                var sender = with
                if item["from"]! == user.senderId {
                    sender = user
                }
                if item["type"]! == "text" {
                    var message = Message(sender: sender, messageId: item["id"]!, sentDate: Date(), kind: .text(item["text"]!), language: item["lang"]!)
                    if userLang != item["lang"]! {
                        dispatchGroup.enter()
                        SwiftGoogleTranslate.shared.translate(item["text"]!, strongSelf.langCodes[userLang]!, strongSelf.langCodes[item["lang"]!]!) { (text, error) in
                            
                            if let t = text {
                                print(t)
                                message.kind = .text(t)
                                print(message)
                            }
                            msgs.append(message)
                            dispatchGroup.leave()
                        }
                    }
                    else {
                        msgs.append(message)
                    }
                    
                }
                if item["type"]! == "image" {
                    let media = Media(url: URL(string: item["link"]!), image: nil, placeholderImage: UIImage(systemName: "info")!, size: CGSize(width: 300, height: 300))
                    let message = Message(sender: sender, messageId: item["id"]!, sentDate: Date(), kind: .photo(media), language: item["lang"]!)
                    msgs.append(message)
                }
                
                if item["type"]! == "location" {
                    let lat = Double(item["lat"]!)
                    let long = Double(item["lng"]!)
                    let location = Location(location: CLLocation(latitude: lat!, longitude: long!), size: CGSize(width: 300, height: 300))
                    let message = Message(sender: sender, messageId: item["id"]!, sentDate: Date(), kind: .location(location), language: item["lang"]!)
                    msgs.append(message)
                }
                
            }
            //            sorts on basis of time and then sends list
            dispatchGroup.notify(queue: DispatchQueue.main) {
                print(msgs)
                msgs.sort { (mOne, mTwo) -> Bool in
                    return mOne.sentDate < mTwo.sentDate
                }
                completion(.success(msgs))
            }
        }
    }
    
    public func deleteChat(with id: String, completion: @escaping(Bool) -> Void) {
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        let ref = database.child("Messages").child(userID).child(id)
        ref.removeValue { (error, _) in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    public func deleteMessageForUser(messageId: String, otherUserId: String, completion: @escaping(Bool) -> Void) {
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        let ref = database.child("Messages").child(userID).child(otherUserId).child(messageId)
        ref.removeValue { (error, _) in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    public func deleteMessageForEveryone(messageId: String, otherUserId: String, completion: @escaping(Bool) -> Void) {
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        deleteMessageForUser(messageId: messageId, otherUserId: otherUserId) { [weak self] (success) in
            guard let strongSelf = self else {
                completion(false)
                return
            }
            if success {
                let ref = strongSelf.database.child("Messages").child(otherUserId).child(userID).child(messageId)
                ref.observeSingleEvent(of: .value) { (snapshot) in
                    if snapshot.exists() {
                        ref.removeValue { (error, _) in
                            guard error == nil else {
                                completion(false)
                                return
                            }
                            completion(true)
                        }
                    }
                }
            }
            else {
                completion(false)
            }
        }
        
    }
    
}


public enum DatabaseErrors: Error {
    case failedToFetchData
    case referenceError
}


struct UserAccount {
    let firstName: String
    let lastName: String
    let email: String
    let image: String
    let language: String
}
