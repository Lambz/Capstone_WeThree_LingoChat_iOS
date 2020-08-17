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
    @IBOutlet weak var userNameLabel: UILabel!
    
    @IBOutlet weak var userImageButton: UIButton!
    private final let settings = ["Profile Settings", "Change Language", "About LingoChat", "Sign out"]
    private final let images = [UIImage(systemName: "person.fill"), UIImage(systemName: "textformat.abc"), UIImage(systemName: "info.circle"), UIImage(systemName: "arrowshape.turn.up.left.fill")]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        setupViews()
        
    }
    
    private func setupViews() {
        guard let url = UserDefaults.standard.object(forKey: "image") as? String else {
            print("data fetch error in settings")
            return
        }
        DispatchQueue.global(qos: .background).async {
            do
            {
                let data = try Data.init(contentsOf: URL(string: url)!)
                DispatchQueue.main.async {
                    print("data converted")
                    self.userImageButton.setImage(UIImage(data: data), for: .normal)
                }
            }
            catch {
                print("image data could not be downloaded in settings")
            }
        }
       
        updateUserName()
        
    }
    
    private func updateUserName() {
        let name = (UserDefaults.standard.object(forKey: "first_name") as! String) + " " + (UserDefaults.standard.object(forKey: "last_name") as! String)
        userNameLabel.text = name
    }
    
    
    @IBAction func imageButtonTapped(_ sender: Any) {
        
    }
}

extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath) as! SettingsTableViewCell
        cell.createSettingsCell(cell: SettingsTableCell(image: images[indexPath.row]!, text: settings[indexPath.row]))
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0: showProfileSettingsAlert()
        case 1: showLanguageSettingAlert()
        case 2: showAboutInfoAlert()
        case 3: showConfirmationAlert()
        default: break
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
    
    private func showProfileSettingsAlert() {
        let alert = UIAlertController(title: "Some Title", message: "Enter a text", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.text = UserDefaults.standard.object(forKey: "first_name") as? String
        }
        alert.addTextField { (textField) in
            textField.text = UserDefaults.standard.object(forKey: "last_name") as? String
        }

        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak alert] (_) in
            let firstName = alert?.textFields![0].text
            let lastName = alert?.textFields![1].text
            if !firstName!.isEmpty && !lastName!.isEmpty {
                DatabaseManager.shared.updateProfile(firstName: firstName!, lastName: lastName!)
                UserDefaults.standard.set(firstName!, forKey: "first_name")
                UserDefaults.standard.set(lastName!, forKey: "last_name")
                self.updateUserName()
            }
            else {
                self.showErrorAlert(message: "Fields can't be empty")
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func showLanguageSettingAlert() {
        
    }
    
    private func showAboutInfoAlert() {
        
    }
    
}
