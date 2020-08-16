//
//  AppDelegate.swift
//  Lingo Chat
//
//  Created by Chetan on 2020-08-09.
//  Copyright © 2020 Chetan. All rights reserved.
//

import UIKit
import Firebase 
import FBSDKCoreKit
import GoogleSignIn
import FirebaseAuth


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        FirebaseApp.configure()
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )

        GIDSignIn.sharedInstance()?.clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance()?.delegate = self
        
        return true
    }
          
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {

        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
        
        return GIDSignIn.sharedInstance().handle(url)

    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard let user = user, error == nil else {
            if let error = error {
                print("Google Sign in error: \(error)")
            }
            return
        }
        
        guard let email = user.profile.email,
            let firstName = user.profile.givenName,
            let lastName = user.profile.familyName else {
                print("Error fetching user details")
                return
        }
        
        guard let authentication = user.authentication else {
            print("Missing sign in auth object for google.")
            return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        
        FirebaseAuth.Auth.auth().signIn(with: credential) { (authResult, error) in
            guard authResult != nil, error == nil else {
                print("Error signing in with google")
                return
            }
            
            DatabaseManager.shared.userAccountExists(with: email) { (exists) in
                
                if !exists {
                    guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else {
                        print("uid not found")
                        return
                    }
                    
                    guard let data = UIImage(named: "user")!.jpegData(compressionQuality: 1.0) else {
                        print("image data not found")
                        return
                    }
                    print("data converted")
                    let fileName = "\(userID).jpeg"
                    StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { (result) in
                        
                        switch result {
                        case .failure(let error):
                            print("Storage manager insertion error: \(error)")
                        case .success(let url):
                            if user.profile.hasImage {
                                guard let profileUrl = user.profile.imageURL(withDimension: 200) else {
                                    return
                                }
                                DatabaseManager.shared.insertUser(with: UserAccount(
                                firstName: firstName,
                                lastName: lastName,
                                email: email,
                                image: profileUrl.absoluteString,
                                language: 0))
                                UserDefaults.standard.set(profileUrl, forKey: "profile_image")
                            }
                            else {
                               DatabaseManager.shared.insertUser(with: UserAccount(
                                firstName: firstName,
                                lastName: lastName,
                                email: email,
                                image: url,
                                language: 0))
                            }
                            
                            UserDefaults.standard.set(true, forKey: "new_user")
                        }
                    }
                }
                
                NotificationCenter.default.post(name: .didGoogleSigninNotification, object: nil)
            }
            
            
        }
        
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print("Google user signed out.")
    }
    
    
}


