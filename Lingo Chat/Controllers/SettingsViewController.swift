//
//  SettingsViewController.swift
//  Lingo Chat
//
//  Created by Chetan on 2020-08-09.
//  Copyright © 2020 Chetan. All rights reserved.
//

import UIKit
import FirebaseAuth
import GoogleSignIn

class SettingsViewController: UIViewController {

    @IBOutlet var tableView: UITableView!
    
    private final let settings = ["Profile Settings", "Change Language", "About LingoChat", "Sign out"]
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
}

extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath)
        cell.textLabel?.text = settings[indexPath.row]
        cell.imageView?.image = UIImage(systemName: "message.fill")
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 3 {
            showConfirmationAlert()
        }
    }
    
    
}

//implements alert methods
extension SettingsViewController {
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Oops!", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    private func showConfirmationAlert() {
        let alert = UIAlertController(title: "Want to log out?", message: "You will be logged out", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Oops", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Log out", style: .default) { (action) in
            
            GIDSignIn.sharedInstance()?.signOut()
            
            do {
                try FirebaseAuth.Auth.auth().signOut()
                self.performSegue(withIdentifier: "logoutUser", sender: self)
            } catch {
                self.showErrorAlert(message: "Unable to log you out.")
            }
            
        })
        self.present(alert, animated: true)
    }
    
}
