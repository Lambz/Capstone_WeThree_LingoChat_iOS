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

