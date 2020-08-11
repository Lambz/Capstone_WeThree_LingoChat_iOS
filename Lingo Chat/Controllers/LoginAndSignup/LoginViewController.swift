//
//  LoginViewController.swift
//  Lingo Chat
//
//  Created by Chetan on 2020-08-09.
//  Copyright © 2020 Chetan. All rights reserved.
//

import UIKit
import CryptoKit
import FirebaseAuth

class LoginViewController: UIViewController {

    @IBOutlet weak var passwordLengthError: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var gmailButton: UIButton!
    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    
    private var encryptedPassword = ""
    
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
        setupFieldIcons()
        setupButtonsShadow()
        passwordLengthError.isHidden = true
    }

}

//implements button handlers
extension LoginViewController {
    @IBAction func loginButtonTapped(_ sender: Any) {
        if checkCredentialsAndLogin() {
            self.performSegue(withIdentifier: "gotoLoggedInScreen", sender: self)
        }
    }
    
    @IBAction func forgotPasswordTapped(_ sender: Any) {
    }
    
    @IBAction func facebookLoginTapped(_ sender: Any) {
    }
    
    @IBAction func gmailLoginTapped(_ sender: Any) {
    }
    
    @IBAction func signupButtonTapped(_ sender: Any) {
        self.performSegue(withIdentifier: "gotoSignupScreen", sender: self)
    }
}


//MARK: implements login methods
extension LoginViewController {
    private func checkCredentialsAndLogin() -> Bool {
        var returnVal = false
        if checkFieldsNotEmpty(){
            returnVal = loginUsingFirebase()
        }
        return returnVal
    }
    
    private func checkFieldsNotEmpty() -> Bool {
        var returnVal = false
        
        guard let email = emailField.text, !email.isEmpty, let password = passwordField.text, !password.isEmpty else {
            showFieldAlert()
            return returnVal
        }
        if password.count > 7 {
            encryptPassword()
            returnVal = true
        }
        return returnVal
    }
    
    private func showFieldAlert() {
        let alert = UIAlertController(title: "Error!", message: "Fields can't be empty", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    private func encryptPassword() {
        let password = passwordField.text!
        let hash = SHA256.hash(data: password.data(using: .utf8)!)
        encryptedPassword = hash.map { String(format: "%02hhx", $0) }.joined()
    }
    
    private func loginUsingFirebase() -> Bool {
        var returnVal = false
        FirebaseAuth.Auth.auth().signIn(withEmail: emailField.text!, password: encryptedPassword) { [weak self] (authResult, error) in
            guard let strongSelf = self else {
                return
            }
            guard let result = authResult, error == nil else {
                strongSelf.showLoginErrorAlert()
                return
            }
            returnVal = true
            let user = result.user
            
        }
        return returnVal
    }
    
    private func showLoginErrorAlert() {
        let alert = UIAlertController(title: "Oops!", message: "Error loggin in user. Please try again later.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
}


//MARK: implements UI methods
extension LoginViewController {
    private func setupFieldLines() {
        emailField.setBottomBorder()
        emailField.addTarget(self, action: #selector(didbegin(_:)), for: .editingDidBegin)
        emailField.addTarget(self, action: #selector(endediting(_:)), for: .editingDidEnd)
        
        passwordField.setBottomBorder()
        passwordField.addTarget(self, action: #selector(didbegin(_:)), for: .editingDidBegin)
        passwordField.addTarget(self, action: #selector(endediting(_:)), for: .editingDidEnd)
    }
    
    private func setupFieldIcons() {
        let accountImg = UIImage(named: "account")
        emailField.setLeftIcon(accountImg!)
        
        let passwordImg = UIImage(named: "password")
        passwordField.setLeftIcon(passwordImg!)
    }
    
    private func setupButtonsShadow() {
        setButtonShadow(button: facebookButton)
        setButtonShadow(button: gmailButton)
        setButtonShadow(button: loginButton)
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
    
    @objc func endediting(_ sender: AnyObject) {
        let border = CALayer()
        let width = CGFloat(0.5)
        border.borderColor = UIColor.black.cgColor
        border.frame = CGRect(x: 0, y: sender.frame.size.height - width, width:  sender.frame.size.width, height: sender.frame.size.height)

        border.borderWidth = width
        sender.layer.addSublayer(border)
        sender.layer.masksToBounds = true
    }
    
}

//MARK: implements UI textfield image methods
extension UITextField {

    func setLeftIcon(_ icon: UIImage) {

        let padding = 8
        let size = 20

        let outerView = UIView(frame: CGRect(x: 0, y: 0, width: size+padding, height: size) )
        let iconView  = UIImageView(frame: CGRect(x: padding, y: 0, width: size, height: size))
        iconView.image = icon
        outerView.addSubview(iconView)

        leftView = outerView
        leftViewMode = .always
    }
    
    func setBottomBorder() {
        self.borderStyle = .none
        self.layer.backgroundColor = UIColor.white.cgColor
        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor.gray.cgColor
        self.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        self.layer.shadowOpacity = 1.0
        self.layer.shadowRadius = 0.0
    }
    
}


