//
//  LoginViewController.swift
//  Lingo Chat
//
//  Created by Chetan on 2020-08-09.
//  Copyright © 2020 Chetan. All rights reserved.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD

class LoginViewController: UIViewController {

    @IBOutlet weak var passwordLengthError: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var gmailButton: UIButton!
    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    
    private var facebookLoginButton: FBLoginButton {
            let button = FBLoginButton()
            button.permissions = ["email,public_profile"]
            return button
    }
    
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
            strongSelf.performSegue(withIdentifier: "gotoLoggedInScreen", sender: strongSelf)
        }
        
        facebookLoginButton.delegate = self
        
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
    
    @IBAction func unwindFromSettings(segue: UIStoryboardSegue) {
        clearFields()
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
        facebookLoginButton.sendActions(for: .touchUpInside)
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


//MARK: implemets facebook login methods
extension LoginViewController: LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        //        no code as no logout button in this screen
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            showErrorAlert(message: "User failed to log in.")
            return
        }
        
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields": "email, name"],
                                                         tokenString: token,
                                                         version: nil, httpMethod: .get)
//        get user details
        facebookRequest.start { [weak self] (_, result, error) in
            guard let strongSelf = self else {
                return
            }
            guard let result = result as? [String: Any], error == nil else {
                print("GraphRequest Fetch Error!")
                return
            }
            
//            check if user with same email already registered
            
            guard let userName = result["name"] as? String,
                let email = result["email"] as? String else {
                    DispatchQueue.main.async {
                        strongSelf.showErrorAlert(message: "Failed to fetch facebook credentials.")
                    }
                    return
            }
//            divide the name into components
            let nameComponents = userName.components(separatedBy: " ")
            guard nameComponents.count == 2 else {
                return
            }
            
            let firstName = nameComponents[0]
            let lastname = nameComponents[1]
            
            DatabaseManager.shared.userAccountExists(with: email) { (exists) in
//                if does not exists then create user
                if !exists {
                    DatabaseManager.shared.insertUser(with: UserAccount(firstName: firstName, lastName: lastname, email: email))
                }
//                continue with login
                let credential = FacebookAuthProvider.credential(withAccessToken: token)
                
                FirebaseAuth.Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
                    guard let strongSelf = self else {
                        return
                    }
                    guard let _ = authResult, error == nil else {
                        DispatchQueue.main.async {
                            strongSelf.showErrorAlert(message: "Facebook login error. MFA may be required.")
                        }
                        return
                    }
                    strongSelf.performSegue(withIdentifier: "gotoLoggedInScreen", sender: strongSelf)
                    
                }
            }
            
        }
        
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
    
    private func clearFields() {
        emailField.text = ""
        passwordField.text = ""
    }
    
}

