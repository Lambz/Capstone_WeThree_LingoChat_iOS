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
    
    /// uploads profile picture to firebase storage and returns url to download
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        
        storage.child("Profile Images").child(fileName).putData(data, metadata: nil) { [weak self] (metadata, error) in
            guard let strongSelf = self else {
                return
            }
            guard error == nil else {
                print("Failed to upload profile picture")
                completion(.failure(StorageErrors.failedToUploadProfilePicture))
                return
            }
            
            strongSelf.storage.child("Profile Images").child(fileName).downloadURL { (url, error) in
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
    
    public func updateProfilePicture(with data: Data, fileName: String, oldUrl: String, completion: @escaping UploadPictureCompletion) {
        
        let oldRef = Storage.storage().reference(forURL: oldUrl)
        oldRef.delete { (error) in
            guard error == nil else {
                print("File deletion error")
                completion(.failure(StorageErrors.failedToDeleteOldPicture))
                return
            }
            
            self.uploadProfilePicture(with: data, fileName: fileName) { (result) in
                switch result {
                case .success(let url):
                    completion(.success(url))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            
        }
    }
    
    /// uploads picture to firebase storage and returns url to download
    public func uploadMessagePicture(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        
        storage.child("Images").child(fileName).putData(data, metadata: nil) { [weak self] (metadata, error) in
            guard let strongSelf = self else {
                return
            }
            guard error == nil else {
                print("Failed to upload profile picture")
                completion(.failure(StorageErrors.failedToUploadProfilePicture))
                return
            }
            
            strongSelf.storage.child("Images").child(fileName).downloadURL { (url, error) in
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
    
    /// uploads video to firebase storage and returns url to download
    public func uploadMessageVideo(with url: URL, fileName: String, completion: @escaping UploadPictureCompletion) {
        let metadata = StorageMetadata()
        metadata.contentType = "video/quicktime"
        guard let videoData = NSData(contentsOf: url) as Data? else {
            completion(.failure(StorageErrors.failedToUploadProfilePicture))
            return
        }
        storage.child("Videos").child(fileName).putData(videoData, metadata: metadata){ [weak self] (metadata, error) in
            guard let strongSelf = self else {
                return
            }
            guard error == nil else {
                print("Failed to upload profile picture")
                completion(.failure(StorageErrors.failedToUploadProfilePicture))
                return
            }
            
            strongSelf.storage.child("Videos").child(fileName).downloadURL { (url, error) in
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
        case failedToDeleteOldPicture
    }
}
