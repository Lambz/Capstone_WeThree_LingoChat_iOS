//
//  OnboardingViewController.swift
//  Lingo Chat
//
//  Created by Chetan on 2020-08-12.
//  Copyright © 2020 Chetan. All rights reserved.
//

import UIKit
import FirebaseAuth

class OnboardingViewController: UIViewController {
    
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var setPreferenceButton: UIButton!
    @IBOutlet weak var skipLabel: UILabel!
    @IBOutlet weak var chatLanguageLabel: UILabel!
    @IBOutlet weak var selectPicLabel: UILabel!
    @IBOutlet weak var completeStepsLabel: UILabel!
    @IBOutlet weak var hithereLabel: UILabel!
    @IBOutlet weak var languageSelector: UISegmentedControl!
    @IBOutlet weak var profilePhotoButton: UIButton!
    private var imagePickerController: UIImagePickerController?
    
    internal var selectedImage: UIImage? {
        get {
            return self.profilePhotoButton.image(for: .normal)
        }
        
        set {
            switch newValue {
            case nil:
                self.profilePhotoButton.setImage(UIImage(named: "user"), for: .normal)
                
            default:
                self.profilePhotoButton.setImage(newValue, for: .normal)
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupButton()
        setupLocalizedText()
        checkIfProfilePicExists()
    }
    
    
    private func setupButton() {
        let button = setPreferenceButton
        button!.layer.shadowColor = #colorLiteral(red: 0.03921568627, green: 0.5176470588, blue: 1, alpha: 1)
        button!.layer.shadowOffset = CGSize(width: 0, height: 0)
        button!.layer.shadowRadius = 8
        button!.layer.shadowOpacity = 0.2
    }
    
    
    private func setupLocalizedText() {
        skipLabel.text = NSLocalizedString("qDc-uG-olW.text", comment: "")
        setPreferenceButton.setTitle(NSLocalizedString("osL-6e-TYe.title", comment: ""), for: .normal)
        skipButton.setTitle(NSLocalizedString("TOY-yo-NWj.title", comment: ""), for: .normal)
        hithereLabel.text = NSLocalizedString("CP9-1f-85Z.text", comment: "")
        completeStepsLabel.text = NSLocalizedString("qtY-sd-0IF.text", comment: "")
        selectPicLabel.text = NSLocalizedString("tL3-eJ-iKn.text", comment: "")
        chatLanguageLabel.text = NSLocalizedString("yJU-XS-a1W.text", comment: "")
        languageSelector.setTitle(NSLocalizedString("English", comment: ""), forSegmentAt: 0)
        languageSelector.setTitle(NSLocalizedString("French", comment: ""), forSegmentAt: 1)
        languageSelector.setTitle(NSLocalizedString("German", comment: ""), forSegmentAt: 2)
        languageSelector.setTitle(NSLocalizedString("Spanish", comment: ""), forSegmentAt: 3)
        languageSelector.setTitle(NSLocalizedString("Hindi", comment: ""), forSegmentAt: 4)
    }
    
    private func checkIfProfilePicExists() {
        guard let url = UserDefaults.standard.url(forKey: "profile_image") else { return }
        
        DispatchQueue.global(qos: .background).async {
            do
            {
                let data = try Data.init(contentsOf: url)
                DispatchQueue.main.async {
                    print("data converted")
                    self.selectedImage = UIImage(data: data)
                }
            }
            catch {
                print("data could not be downloaded")
            }
        }
        UserDefaults.standard.removeObject(forKey: "profile_image")
        
    }
    
    @IBAction func profilePhotoButtonTapped(_ sender: Any) {
        presentPhotoActionSheet()
    }
    @IBAction func saveButtonTapped(_ sender: Any) {
        performOnbardingDataInsertion()
    }
    
    @IBAction func skipButtonTapped(_ sender: Any) {
        performOnbardingDataInsertion()
    }
    
    private func performOnbardingDataInsertion() {
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else {
            return
        }
        guard let data = selectedImage?.jpegData(compressionQuality: 1.0) else {
            return
        }
        print("data converted")
        let fileName = "\(userID).jpeg"
        StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { [weak self](result) in
            switch result {
            case .failure(let error):
                print("Storage manager insertion error: \(error)")
            case .success(let url):
                DatabaseManager.shared.insertPreferences(image: url, language: "\((self?.languageSelector.selectedSegmentIndex)!)")
                self?.performSegue(withIdentifier: "gotoLoggedInScreen", sender: self)
            }
        }
        
    }
}



extension OnboardingViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
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
}
