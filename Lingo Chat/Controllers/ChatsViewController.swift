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
import SDWebImage

struct Chat {
    let otherPersonId: String
    let otherPersonName: String
    let otherPersonImage: String
    var otherPersonLastMessage: String
    let otherPersonEmail: String
    let otherPersonLanguage: String
}

class ChatsViewController: UIViewController {

    
    @IBOutlet weak var chats: UINavigationItem!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyChatsLabel: UILabel!
    private let spinner = JGProgressHUD(style: .light)
    private var selectedContactToStartConversation : UserAccount!
    private var previousChats = [Chat]()
    private var images = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLocalizationText()
        setupInitialView()
        setupTableView()
        fetchUserDetails()
        DatabaseManager.shared.checkIfAnyConversation { [weak self] (exists) in
            guard let strongSelf = self else {
                return
            }
            if exists {
                strongSelf.fetchChatsFromFirebase { (_) in
                    strongSelf.tableView.reloadData()
                    strongSelf.fetchImages { (_) in
                        strongSelf.tableView.reloadData()
                    }
                }
            }
            else {
                strongSelf.emptyChatsLabel.isHidden = false
                strongSelf.tableView.isHidden = true
            }
        }
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.navigationItem.hidesBackButton = true
        self.tabBarController?.tabBar.isHidden = false
        self.tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.resignFirstResponder()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.destination is ConversationViewController else {
            return
        }
    
        if let destVC = segue.destination as? ConversationViewController {
            let title = selectedContactToStartConversation.firstName + " " + selectedContactToStartConversation.lastName
            destVC.isNewConversation = true
            destVC.title = title
            destVC.otherUser = selectedContactToStartConversation
        }
        
    }

    @IBAction func addChatButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "showContactsScreen", sender: self)
    }
    
    @IBAction func unwindFromSettings(segue: UIStoryboardSegue) {
        if segue.source is ContactsViewController {
            if let senderVC = segue.source as? ContactsViewController {
                selectedContactToStartConversation = senderVC.selectedContact
                if let segue = segue as? UIStoryboardSegueWithCompletion {
                    segue.completion = {
                        self.performSegue(withIdentifier: "gotoConversationScreen", sender: self)
                    }
                }
            }
        }
    }
    
    
}

extension ChatsViewController {
    
    private func setupLocalizationText() {
        chats.title = NSLocalizedString("wgz-o6-ZPJ.title", comment: "")
        emptyChatsLabel.text = NSLocalizedString("pWs-h6-O3R.text", comment: "")
    }
    
    private func setupInitialView() {
        tableView.isHidden = true
        emptyChatsLabel.isHidden = false
    }

    private func fetchChatsFromFirebase(completion: @escaping(Bool) -> Void) {
        DatabaseManager.shared.getAllConversations { [weak self] (result) in
            guard let strongSelf = self else {
                completion(false)
                return
            }
            print("fetching conversation")
            switch result {
            case .success(let list):
                if list.isEmpty {
                    strongSelf.emptyChatsLabel.isHidden = false
                    strongSelf.tableView.isHidden = true
                    strongSelf.previousChats.removeAll()
                    strongSelf.images.removeAll()
                }
                else {
                    strongSelf.emptyChatsLabel.isHidden = true
                    strongSelf.tableView.isHidden = false
                    strongSelf.setupImages(count: list.count)
                    strongSelf.previousChats.removeAll()
                    var i = 0
                    for item in list {
                        let chat = Chat(otherPersonId: item.id, otherPersonName: item.name, otherPersonImage: item.image, otherPersonLastMessage: "Loading...", otherPersonEmail: item.email, otherPersonLanguage: item.language)
                        strongSelf.previousChats.insert(chat, at: i)
                        print("here before crashing")
                        strongSelf.fetchLastMessages(index: i, completion: { (_) in
                            strongSelf.tableView.reloadData()
                        })
                        i += 1
                    }
                }
                completion(true)
            case .failure(let error):
                strongSelf.emptyChatsLabel.isHidden = false
                strongSelf.emptyChatsLabel.text = "An error occured while fetching data!"
                strongSelf.tableView.isHidden = true
                print("Data fetch error: \(error)")
                completion(false)
            }
        }
    }
    
    
    private func fetchLastMessages(index: Int, completion: @escaping(Bool) -> Void) {
        DatabaseManager.shared.getLastMessage(with: previousChats[index].otherPersonId) { [weak self](result) in
            guard let strongSelf = self else {
                completion(false)
                return
            }
            switch result {
            case .success(let message):
                if !strongSelf.previousChats.isEmpty {
                    var chat = strongSelf.previousChats.remove(at: index)
                    chat.otherPersonLastMessage = message
                    strongSelf.previousChats.insert(chat, at: index)
                    completion(true)
                }
            case .failure(let error):
                if !strongSelf.previousChats.isEmpty {
                    var chat = strongSelf.previousChats.remove(at: index)
                    chat.otherPersonLastMessage = "Failed to fetch data"
                    strongSelf.previousChats.insert(chat, at: index)
                    print("Error fetching message: \(error)")
                    completion(false)
                }
            }
        }
        
        
    }
    
    private func setupImages(count: Int) {
        images.removeAll()
        for _ in 1...count {
            images.append(UIImage(named: "user")!)
        }
    }
    
    private func fetchImages(completion: @escaping(Bool) -> Void) {
        let downloader = SDWebImageManager()

        for i in 0..<previousChats.count {
            guard !previousChats[i].otherPersonImage.isEmpty else {
                continue
            }
            downloader.loadImage(with: URL(string: previousChats[i].otherPersonImage), options: .highPriority, progress: nil) { [weak self] (image, _, error, _, _, _) in
                guard error == nil, image != nil else {
                    return
                }
                print(i)
                self?.images[i] = image!
                self?.tableView.reloadData()
            }
        }
        completion(true)
    }
    
    private func fetchUserDetails() {
        DatabaseManager.shared.getUserDetails { (result) in
            switch result {
            case .success(let values):
                UserDefaults.standard.set(values[0] , forKey: "first_name")
                UserDefaults.standard.set(values[1] , forKey: "last_name")
                UserDefaults.standard.set(values[2] , forKey: "image")
                UserDefaults.standard.set(values[3], forKey: "language")
                UserDefaults.standard.set(values[4], forKey: "user_id")
            case .failure(let error):
                print("Data fetch error: \(error)")
            }
        }
    }
    
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
    }
}

extension ChatsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return previousChats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatCell", for: indexPath) as! ChatsTableViewCell
        cell.createChatCell(image: images[indexPath.row], senderName: previousChats[indexPath.row].otherPersonName, lastMsg: previousChats[indexPath.row].otherPersonLastMessage)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let names = previousChats[indexPath.row].otherPersonName.components(separatedBy: " ")
        let user = UserAccount(firstName: names[0], lastName: names[1], email: previousChats[indexPath.row].otherPersonEmail, image: previousChats[indexPath.row].otherPersonImage, language: previousChats[indexPath.row].otherPersonLanguage)
        selectedContactToStartConversation = user
        self.performSegue(withIdentifier: "gotoConversationScreen", sender: self)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            
            DatabaseManager.shared.deleteChat(with: previousChats[indexPath.row].otherPersonId) { (_) in
                
                }
            tableView.endUpdates()
            if previousChats.isEmpty {
                emptyChatsLabel.isHidden = false
                tableView.isHidden = true
            }
        }
        
    }
}

