//
//  SignupViewController.swift
//  Lingo Chat
//
//  Created by Chetan on 2020-08-09.
//  Copyright © 2020 Chetan. All rights reserved.
//

import UIKit
import FirebaseAuth

class SignupViewController: UIViewController {

    @IBOutlet weak var passwordMismatchError: UILabel!
    @IBOutlet weak var passwordLengthError: UILabel!
    @IBOutlet weak var confirmPasswordField: UITextField!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var lastNameField: UITextField!
    @IBOutlet weak var firstNameField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    private func setupViews() {
        setupFieldLines()
        setButtonShadow(button: signupButton)
        signupButton.addTarget(self, action: #selector(signupButtonPressed), for: .touchUpInside)
        hideLabels()
    }
}

//MARK: implements the signup methods
extension SignupViewController {
//    called on button press
    @objc func signupButtonPressed() {
    //        check fields
            validateFieldsForNonEmptyAndPasswordMatch()
        
    //        signup after email verification
//        if passwordField.text! == confirmPasswordField.text! {
//            DatabaseManager.shared.userAccountExists(with: emailField.text!, completion: { [weak self] (exists) in
//                guard let strongSelf = self else {
//                    return
//                }
//                guard !exists else {
//                    strongSelf.showErrorAlert(message: "User with same email address already exists.")
//                    return
//                }
//                strongSelf.doLoginUsingFirebase()
//            })
//        }
    }
    
    private func validateFieldsForNonEmptyAndPasswordMatch() {
        guard let firstName = firstNameField.text, !firstName.isEmpty,
            let lastName = lastNameField.text, !lastName.isEmpty,
            let email = emailField.text, !email.isEmpty,
            let password = passwordField.text, !password.isEmpty,
            let confirmedPassword = confirmPasswordField.text, !confirmedPassword.isEmpty
        else {
            showErrorAlert(message: "Fields can't be empty.")
            return
        }
        doLoginUsingFirebase()
    }
    
    private func doLoginUsingFirebase() {
        FirebaseAuth.Auth.auth().createUser(withEmail: emailField.text!, password: passwordField.text!) { [weak self](authResult, error) in
            guard let strongSelf = self else {
                return
            }
            guard let _ = authResult, error == nil else {
                DispatchQueue.main.async {
                    strongSelf.showErrorAlert(message: "Error creating user. Please try again later.")
                }
                return
            }
            strongSelf.insertDatatoDatabase()
        }
    }
    
    private func insertDatatoDatabase() {
        let userID = FirebaseAuth.Auth.auth().currentUser?.uid
        guard let data = UIImage(named: "user")!.jpegData(compressionQuality: 1.0) else {
            return
        }
        print("data converted")
        let fileName = "\(userID).jpeg"
        StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { [weak self](result) in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .failure(let error):
                print("Storage manager insertion error: \(error)")
            case .success(let url):
                DatabaseManager.shared.insertUser(with: UserAccount(
                    firstName: strongSelf.firstNameField.text!,
                    lastName: strongSelf.lastNameField.text!,
                    email: strongSelf.emailField.text!,
                    image: url,
                    language: 0))
                strongSelf.performSegue(withIdentifier: "gotoOnboardingScreen", sender: self)
            }
        }
        
    }
    
//    alert method implemented
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Oops!", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
}

//MARK: implements UI methods
extension SignupViewController {
    private func setupFieldLines() {
        setFieldLines(field: firstNameField)
        setFieldLines(field: lastNameField)
        setFieldLines(field: emailField)
        setFieldLines(field: passwordField)
        setFieldLines(field: confirmPasswordField)
    }
    
    private func setFieldLines(field: UITextField) {
        field.setBottomBorder()
        field.addTarget(self, action: #selector(didbegin(_:)), for: .editingDidBegin)
        field.addTarget(self, action: #selector(endediting(_:)), for: .editingDidEnd)
        field.addTarget(self, action: #selector(didEditText(_:)), for: .editingChanged)
    }
    
    private func setButtonShadow(button: UIButton) {
        button.layer.shadowColor = #colorLiteral(red: 0.03921568627, green: 0.5176470588, blue: 1, alpha: 1)
        button.layer.shadowOffset = CGSize(width: 0, height: 0)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.2
    }
    
    @objc func didbegin(_ sender: UITextField) {
        let border = CALayer()
        let width = CGFloat(0.5)
        border.borderColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
        
        border.frame = CGRect(x: 0, y: sender.frame.size.height - width, width:  sender.frame.size.width, height: sender.frame.size.height)

        border.borderWidth = width
        sender.layer.addSublayer(border)
        sender.layer.masksToBounds = true
    }
    
    @objc func didEditText(_ sender: UITextField) {
        if sender == passwordField {
            if sender.text!.count < 8 && !sender.text!.isEmpty {
                passwordLengthError.isHidden = false
            }
            else {
                passwordLengthError.isHidden = true
            }
        }
        if sender == confirmPasswordField {
            if sender.text != passwordField.text && !sender.text!.isEmpty {
                passwordMismatchError.isHidden = false
            }
            else {
                passwordMismatchError.isHidden = true
            }
        }
    }
    
    @objc func endediting(_ sender: AnyObject) {
        let border = CALayer()
        let width = CGFloat(0.5)
        border.borderColor = UIColor.black.cgColor
        
        border.frame = CGRect(x: 0, y: sender.frame.size.height - width, width:  sender.frame.size.width, height: sender.frame.size.height)

        border.borderWidth = width
        sender.layer.addSublayer(border)
        sender.layer.masksToBounds = true
    }
    
    private func hideLabels() {
        passwordLengthError.isHidden = true
        passwordMismatchError.isHidden = true
    }
}
