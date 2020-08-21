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
import SDWebImage

class SettingsViewController: UIViewController {

    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var userNameLabel: UILabel!
    
    @IBOutlet weak var userImageButton: UIButton!
    private final let settings = ["Profile Settings", "Change Language", "About LingoChat", "Sign out"]
    private final let images = [UIImage(systemName: "person.fill"), UIImage(systemName: "textformat.abc"), UIImage(systemName: "info.circle"), UIImage(systemName: "arrowshape.turn.up.left.fill")]
    
    private var imagePickerController: UIImagePickerController?
    
    internal var selectedImage: UIImage? {
        get {
            return self.userImageButton.image(for: .normal)
        }
        
        set {
            switch newValue {
            case nil:
                self.userImageButton.setImage(UIImage(named: "user"), for: .normal)
                
            default:
                self.userImageButton.setImage(newValue, for: .normal)
            }
        }
    }
    
    
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
        DispatchQueue.main.async {
            self.userImageButton.sd_setImage(with: URL(string: url)!, for: .normal, completed: nil)
        }
        
//        DispatchQueue.global(qos: .background).async {
//            do
//            {
//                let data = try Data.init(contentsOf: URL(string: url)!)
//                DispatchQueue.main.async {
//                    print("data converted")
//                    self.userImageButton.setImage(UIImage(data: data), for: .normal)
//                }
//            }
//            catch {
//                print("image data could not be downloaded in settings")
//            }
//        }
//
        updateUserName()
        
    }
    
    private func updateUserName() {
        let name = (UserDefaults.standard.object(forKey: "first_name") as! String) + " " + (UserDefaults.standard.object(forKey: "last_name") as! String)
        userNameLabel.text = name
    }
    
    
    @IBAction func imageButtonTapped(_ sender: Any) {
        presentPhotoActionSheet()
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
    private func showErrorAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
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
                self.showErrorAlert(title: "Oops!", message: "Unable to log you out.")
            }
            
        })
        self.present(alert, animated: true)
    }
    
    private func showProfileSettingsAlert() {
        let alert = UIAlertController(title: "Change your profile", message: "Enter text to update values", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.text = UserDefaults.standard.object(forKey: "first_name") as? String
            textField.layoutMargins = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
            textField.placeholder = "First Name"
        }
        alert.addTextField { (textField) in
            textField.text = UserDefaults.standard.object(forKey: "last_name") as? String
            textField.layoutMargins = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
            textField.placeholder = "Last Name"
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
                self.showErrorAlert(title: "Invalid input", message: "Fields can't be empty")
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func showLanguageSettingAlert() {
        let alert = UIAlertController(title: "Change your language", message: "0: English, 1: French, 2:German, 3:Spanish, 4.Hindi", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.text = UserDefaults.standard.object(forKey: "language") as? String
            textField.layoutMargins = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
            textField.placeholder = "Enter language code"
        }
       
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak alert] (_) in
            let code = alert?.textFields![0].text
        
            guard code != nil else {
                self.showErrorAlert(title: "Invalid input!", message: "Fields can't be empty")
                return
            }
            if !code!.isEmpty {
                switch code {
                case "0": DatabaseManager.shared.updateLanguage(language: "0")
                    UserDefaults.standard.set("0", forKey: "language")
                case "1": DatabaseManager.shared.updateLanguage(language: "1")
                    UserDefaults.standard.set("1", forKey: "language")
                case "2": DatabaseManager.shared.updateLanguage(language: "2")
                    UserDefaults.standard.set("2", forKey: "language")
                case "3": DatabaseManager.shared.updateLanguage(language: "3")
                    UserDefaults.standard.set("3", forKey: "language")
                case "4": DatabaseManager.shared.updateLanguage(language: "4")
                    UserDefaults.standard.set("4", forKey: "language")
                default: self.showErrorAlert(title: "Sorry!", message: "Invalid input")
                }
            }
            else {
                self.showErrorAlert(title: "Sorry", message: "Fields can't be empty")
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func showAboutInfoAlert() {
        let title = "Welcome to LingoChat!"
        let message = "LingoChat is an app created for facilitating inter-lingustic communication between people. The aim of this app is to improve the way peple connect."
        showErrorAlert(title: title, message: message)
    }
}


extension SettingsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func presentPhotoActionSheet() {
        if self.imagePickerController != nil {
            self.imagePickerController?.delegate = nil
            self.imagePickerController = nil
        }
        
        self.imagePickerController = UIImagePickerController.init()
        
        let alert = UIAlertController.init(title: "Select Source Type", message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction.init(title: "Camera", style: .default, handler: { (_) in
                self.showCamera()
            }))
        }
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alert.addAction(UIAlertAction.init(title: "Photo Library", style: .default, handler: { (_) in
                self.showGallery()
            }))
        }
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel))
        
        self.present(alert, animated: true)
    }
    
    func showCamera() {
        imagePickerController = UIImagePickerController()
        imagePickerController!.sourceType = .camera
        imagePickerController!.delegate = self
        imagePickerController!.allowsEditing = true
        self.present(imagePickerController!, animated: true)
    }
    
    func showGallery() {
        imagePickerController = UIImagePickerController()
        imagePickerController!.sourceType = .photoLibrary
        imagePickerController!.delegate = self
        imagePickerController!.allowsEditing = true
        self.present(imagePickerController!, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            return
        }
        self.selectedImage = selectedImage
        saveImage()
        picker.dismiss(animated: true) {
            picker.delegate = nil
            self.imagePickerController = nil
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) {
            picker.delegate = nil
            self.imagePickerController = nil
        }
    }
    
    func saveImage() {
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else {
            return
        }
        guard let data = selectedImage?.jpegData(compressionQuality: 1.0) else {
            return
        }
        print("data converted")
        let fileName = "\(userID).jpeg"
        StorageManager.shared.updateProfilePicture(with: data, fileName: fileName, oldUrl: UserDefaults.standard.object(forKey: "image") as! String) { (result) in
            switch result {
            case .failure(let error):
                print("Storage manager updation error: \(error)")
            case .success(let url):
                DatabaseManager.shared.updateImageUrl(image: url)
            }
        }
    }
}
