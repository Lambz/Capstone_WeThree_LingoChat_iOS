//
//  LoginViewController.swift
//  Lingo Chat
//
//  Created by Chetan on 2020-08-09.
//  Copyright © 2020 Chetan. All rights reserved.
//

import UIKit
import FirebaseAuth
import GoogleSignIn
import JGProgressHUD

class LoginViewController: UIViewController {

    @IBOutlet weak var passwordLengthError: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var gmailButton: UIButton!
    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    
    
    private var googleSignInButton = GIDSignInButton()
    private var googleSignInObserver: NSObjectProtocol?
    
    private var spinner = JGProgressHUD(style: .dark)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        
        googleSignInObserver = NotificationCenter.default.addObserver(forName: .didGoogleSigninNotification, object: nil, queue: .main) { [weak self] (_) in
            guard let strongSelf = self else {
                return
            }
            if UserDefaults.standard.object(forKey: "new_user") != nil {
                UserDefaults.standard.removeObject(forKey: "new_user")
                strongSelf.performSegue(withIdentifier: "gotoOnboardingScreen", sender: strongSelf)
            }
            else {
               strongSelf.performSegue(withIdentifier: "gotoLoggedInScreen", sender: strongSelf)
            }
            
        }
        
        GIDSignIn.sharedInstance()?.presentingViewController = self
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
    
    deinit {
        if let observer = googleSignInObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

}

//implements button handlers
extension LoginViewController {
    @IBAction func loginButtonTapped(_ sender: Any) {
        checkCredentialsAndLogin()
    }
    
    @IBAction func forgotPasswordTapped(_ sender: Any) {
    }
    
    @IBAction func facebookLoginTapped(_ sender: Any) {
        
    }
    
    @IBAction func gmailLoginTapped(_ sender: Any) {
        googleSignInButton.sendActions(for: .touchUpInside)
    }
    
    @IBAction func signupButtonTapped(_ sender: Any) {
        self.performSegue(withIdentifier: "gotoSignupScreen", sender: self)
    }
}


//MARK: implements login methods
extension LoginViewController {
    private func checkCredentialsAndLogin() {
//        checks fields not empty
        guard let email = emailField.text, !email.isEmpty, let password = passwordField.text, !password.isEmpty else {
            showErrorAlert(message: "Fields can't be empty.")
            return
        }
        
        spinner.show(in: view)
//        checks password atleast 8 characters
        if password.count > 7 {
            FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self] (authResult, error) in
                guard let strongSelf = self else {
                    return
                }
                DispatchQueue.main.async {
                    strongSelf.spinner.dismiss()
                }
                guard authResult != nil, error == nil else {
                    DispatchQueue.main.async {
                        strongSelf.showErrorAlert(message: "Error signing in user. Please try again later.")
                    }
                    return
                }
                strongSelf.performSegue(withIdentifier: "gotoLoggedInScreen", sender: strongSelf)
            }
        }
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Oops!", message: message, preferredStyle: .alert)
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

