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
    @IBOutlet weak var settingsTitle: UINavigationItem!
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var userNameLabel: UILabel!
    
    @IBOutlet weak var userImageButton: UIButton!
    private final let settings = [NSLocalizedString("ProfileSettings", comment: ""), NSLocalizedString("ChangeLanguage", comment: ""), NSLocalizedString("AboutLingoChat", comment: ""), NSLocalizedString("SignOut", comment: "")]
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
        settingsTitle.title = NSLocalizedString("186-Ug-MkN.title", comment: "")
        guard let url = UserDefaults.standard.object(forKey: "image") as? String else {
            print("data fetch error in settings")
            return
        }
        DispatchQueue.main.async {
            self.userImageButton.sd_setImage(with: URL(string: url)!, for: .normal, completed: nil)
        }
        updateUserName()
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
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
        let alert = UIAlertController(title: NSLocalizedString("LogoutTitle", comment: ""), message: NSLocalizedString("LogoutMessage", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Oops", comment: ""), style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("LogOut", comment: ""), style: .default) { [weak self] (action) in
            guard let strongSelf = self else {
                return
            }
            
            GIDSignIn.sharedInstance()?.signOut()
            
            do {
                try FirebaseAuth.Auth.auth().signOut()
                strongSelf.clearUserDefaults()
                strongSelf.performSegue(withIdentifier: "logoutUser", sender: self)
            } catch {
                strongSelf.showErrorAlert(title: NSLocalizedString("Oops", comment: ""), message: NSLocalizedString("UnableLogOut", comment: ""))
            }
            
        })
        self.present(alert, animated: true)
    }
    
    private func clearUserDefaults() {
        UserDefaults.standard.removeObject(forKey: "first_name")
        UserDefaults.standard.removeObject(forKey: "last_name")
        UserDefaults.standard.removeObject(forKey: "image")
        UserDefaults.standard.removeObject(forKey: "language")
        UserDefaults.standard.removeObject(forKey: "user_id")
    }
    
    private func showProfileSettingsAlert() {
        let alert = UIAlertController(title: NSLocalizedString("UpdateProfileTitle", comment: ""), message: NSLocalizedString("UpdateProfileMessage", comment: ""), preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.text = UserDefaults.standard.object(forKey: "first_name") as? String
            textField.layoutMargins = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
            textField.placeholder = NSLocalizedString("0HL-bT-ob3.placeholder", comment: "")
        }
        alert.addTextField { (textField) in
            textField.text = UserDefaults.standard.object(forKey: "last_name") as? String
            textField.layoutMargins = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
            textField.placeholder = NSLocalizedString("piS-CH-Mby.placeholder", comment: "")
        }

        alert.addAction(UIAlertAction(title: NSLocalizedString("Save", comment: ""), style: .default, handler: { [weak alert] (_) in
            let firstName = alert?.textFields![0].text
            let lastName = alert?.textFields![1].text
            if !firstName!.isEmpty && !lastName!.isEmpty {
                DatabaseManager.shared.updateProfile(firstName: firstName!, lastName: lastName!)
                UserDefaults.standard.set(firstName!, forKey: "first_name")
                UserDefaults.standard.set(lastName!, forKey: "last_name")
                self.updateUserName()
            }
            else {
                self.showErrorAlert(title: NSLocalizedString("InvalidInput!", comment: ""), message: NSLocalizedString("EmptyFieldsAlert", comment: ""))
            }
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func showLanguageSettingAlert() {
        let alert = UIAlertController(title: NSLocalizedString("languageAlertTitle", comment: ""), message: NSLocalizedString("LanguageAlertOptions", comment: ""), preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.text = UserDefaults.standard.object(forKey: "language") as? String
            textField.layoutMargins = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
            textField.placeholder = NSLocalizedString("languagePlaceholder", comment: "")
        }
       
        alert.addAction(UIAlertAction(title: NSLocalizedString("Save", comment: ""), style: .default, handler: { [weak alert] (_) in
            let code = alert?.textFields![0].text
        
            guard code != nil else {
                self.showErrorAlert(title: NSLocalizedString("InvalidInput!", comment: ""), message: NSLocalizedString("EmptyFieldsAlert", comment: ""))
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
                self.showErrorAlert(title: NSLocalizedString("Sorry!", comment: ""), message: NSLocalizedString("EmptyFieldsAlert", comment: ""))
            }
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func showAboutInfoAlert() {
        let title = NSLocalizedString("InfoTitle", comment: "")
        let message = NSLocalizedString("InfoMessage", comment: "")
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
        
        let alert = UIAlertController.init(title: NSLocalizedString("SelectSource", comment: ""), message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction.init(title: NSLocalizedString("Camera", comment: ""), style: .default, handler: { (_) in
                self.showCamera()
            }))
        }
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alert.addAction(UIAlertAction.init(title: NSLocalizedString("PhotoLibrary", comment: ""), style: .default, handler: { (_) in
                self.showGallery()
            }))
        }
        
        alert.addAction(UIAlertAction.init(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
        
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
