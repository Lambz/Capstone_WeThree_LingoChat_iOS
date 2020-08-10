//
//  AnimatedLogoViewController.swift
//  Lingo Chat
//
//  Created by Chetan on 2020-08-10.
//  Copyright © 2020 Chetan. All rights reserved.
//

import UIKit

class AnimatedLogoViewController: UIViewController {

    private let logoView: UIImageView = {
        let logoView = UIImageView(frame: CGRect(x: 0,
                                                 y: 0,
                                                 width: 200,
                                                 height: 200))
        logoView.image = UIImage(named: "user")
        return logoView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(logoView)
        DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
            self.animateLogo()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        logoView.center = view.center
    }
    
    private func animateLogo() {
        UIView.animate(withDuration: 1) {
            let size = self.view.frame.size.width * 3
            let diffX = size - self.view.frame.size.width
            let diffY = self.view.frame.size.height - size
            self.logoView.frame = CGRect(x: -(diffX/2),
                                         y: diffY/2,
                                         width: size,
                                         height: size)
        }
        
        UIView.animate(withDuration: 1, animations: {
            self.logoView.alpha = 0
        }) { done in
            //        checks if user already logged in
            if UserDefaults.standard.bool(forKey: "isSignedIn") {
                self.performSegue(withIdentifier: "userLoggedIn", sender: self)
            }
            else {
                self.performSegue(withIdentifier: "userNotLoggedIn", sender: self)
            }
        }
    }
    

}
