//
//  StorageManager.swift
//  Lingo Chat
//
//  Created by Chetan on 2020-08-13.
//  Copyright © 2020 Chetan. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseAuth

final class StorageManager {
    public static let shared = StorageManager()
    private let storage = Storage.storage().reference()
    
    /*
     URL: /profile_image/userID.png/
     */
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    
/// uploads picture to firebase storage and returns url to download
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else {
            return
        }
        
        storage.child("Profile Images").child(userID).putData(data, metadata: nil) { [weak self] (metadata, error) in
            guard let strongSelf = self else {
                return
            }
            guard error == nil else {
                print("Failed to upload profile picture")
                completion(.failure(StorageErrors.failedToUploadProfilePicture))
                return
            }
            
            strongSelf.storage.child("Profile Images").child(userID).downloadURL { (url, error) in
                guard let url = url else {
                    print("Failed to fetch profile picture URL")
                    completion(.failure(StorageErrors.failedToFetchProfilePictureURL))
                    return
                }
                
                let urlString = url.absoluteString
                print("Download string returned: \(urlString)")
                completion(.success(urlString))
                
            }
        }
        
    }
    
    
    public enum StorageErrors: Error {
        case failedToUploadProfilePicture
        case failedToFetchProfilePictureURL
    }
}
