//
//  ViewController.swift
//  Lingo Chat
//
//  Created by Chetan on 2020-08-09.
//  Copyright © 2020 Chetan. All rights reserved.
//

import UIKit
import FirebaseAuth
import JGProgressHUD


class ChatsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyChatsLabel: UILabel!
    private let spinner = JGProgressHUD(style: .light)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupInitialView()
        setupTableView()
        fetchUserDetails()
        fetchChatsFromFirebase()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.navigationItem.hidesBackButton = true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.destination is ConversationViewController else {
            return
        }
        
        segue.destination.title = "Person"
        
    }

    @IBAction func addChatButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "showContactsScreen", sender: self)
    }
    
    @IBAction func unwindFromSettings(segue: UIStoryboardSegue) {
        
    }
    
    
}

extension ChatsViewController {
    private func setupInitialView() {
        tableView.isHidden = true
        emptyChatsLabel.isHidden = true
    }

    private func fetchChatsFromFirebase() {
        tableView.isHidden = false
    }
    
    
    private func fetchUserDetails() {
        DatabaseManager.shared.getUserDetails { (result) in
            switch result {
            case .success(let values):
                UserDefaults.standard.set(values[0] as! String, forKey: "first_name")
                UserDefaults.standard.set(values[1] as! String, forKey: "last_name")
                UserDefaults.standard.set(values[2] as! String, forKey: "image")
                UserDefaults.standard.set(values[3] as! Int, forKey: "language")
            case .failure(let error):
                print("Data fetch error: \(error)")
            }
        }
    }
    
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
}

extension ChatsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatCell", for: indexPath)
        cell.textLabel?.text = "Cell"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.performSegue(withIdentifier: "gotoConversationScreen", sender: self)
    }
}

