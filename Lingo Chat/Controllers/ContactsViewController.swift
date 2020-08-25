//
//  ContactsViewController.swift
//  Lingo Chat
//
//  Created by Chetan on 2020-08-09.
//  Copyright © 2020 Chetan. All rights reserved.
//

import UIKit
import JGProgressHUD
import SDWebImage

class ContactsViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var noContactsLabel: UILabel!
    private var personalContacts = [String]()
    private var contactsToShow: [UserAccount] = []
    public var selectedContact: UserAccount!
    private var hasFetched = false
    private var images: [UIImage] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocalizationText()
        setupDelegates()
        setupContactsData { [weak self] (success) in
            if success {
                self?.downloadImages { (_) in
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    private func setupLocalizationText() {
        searchBar.placeholder = NSLocalizedString("zWJ-Wc-7vS.placeholder", comment: "")
        noContactsLabel.text = NSLocalizedString("HXC-6H-hip.text", comment: "")
        cancelButton.setTitle(NSLocalizedString("R65-9X-KKN.title", comment: ""), for: .normal)
    }
    
    private func setupDelegates() {
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        searchBar.becomeFirstResponder()
        tableView.isHidden = true
        noContactsLabel.isHidden = true
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
    }
    
    private func setupContactsData(completion: @escaping(Bool) -> Void) {
        personalContacts = ContactsHelper.fetchContacts()
        if !personalContacts.isEmpty {
            spinner.show(in: view)
            personalContacts = personalContacts.map{$0.lowercased()}
            fetchContacts { [weak self] (result) in
                guard let strongSelf = self else {
                    completion(false)
                    return
                }
                print("contacts fetched")
                strongSelf.spinner.dismiss()
                switch result {
                case .success(let isNotEmpty):
                    if isNotEmpty {
//                        refresh view
                        strongSelf.createInitialImages(count: strongSelf.contactsToShow.count)
                        strongSelf.tableView.isHidden = false
                        completion(true)
                    }
                    else {
                        strongSelf.noContactsLabel.isHidden = false
                        completion(false)
                    }
                case .failure(let error):
                    print("Failed to fetch contacts: \(error)")
                    strongSelf.spinner.dismiss()
                    strongSelf.noContactsLabel.isHidden = false
                }
            }
        }
        else {
           noContactsLabel.isHidden = false
        }
    }
    
    private func createInitialImages(count: Int) {
        images.removeAll()
        for _ in 1...count {
            images.append(UIImage(named: "user")!)
        }
    }
    
    private func downloadImages(completion: @escaping(Bool)->Void) {
        var index = 0
        let downloader = SDWebImageManager()
        
        for i in 0..<contactsToShow.count {
           
            if !contactsToShow[i].image.isEmpty {
                downloader.loadImage(with: URL(string: contactsToShow[i].image)!, options: .highPriority, progress: nil) { [weak self] (image, _, error, _, _, _) in
                    guard error == nil, image != nil else {
                        print("image fetch failure")
                        return
                    }
                    print("image fetched and appended")
                    self?.images[i] = image!
                    self?.tableView.reloadData()
                }
            }
            index += 1
        }
        completion(true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        tableView.reloadData()
        view.endEditing(true)
        
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.resignFirstResponder()
    }
    

    @IBAction func cancelButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}


extension ContactsViewController {
    private func fetchContacts(completion: @escaping (Result<Bool, Error>) -> Void) {
        if !hasFetched {
            DatabaseManager.shared.fetchAllUsers { (result) in
                switch result {
                case .success(let users):
                    for user in users {
                        if self.personalContacts.contains(user.email.lowercased()) {
                            self.contactsToShow.append(user)
                        }
                    }
                    if(self.contactsToShow.isEmpty) {
                        completion(.success(false))
                    }
                    else {
                        completion(.success(true))
                    }
                case .failure(let error):
                    print("Failed to fetch contacts: \(error)")
                    completion(.failure(DatabaseErrors.failedToFetchData))
                }
                self.hasFetched = true
            }
        }
        
        
    }
}


extension ContactsViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }

        searchBar.resignFirstResponder()
        spinner.show(in: view)
        searchUsers(query: text)
    }
    
    
    func searchUsers(query: String) {
        
    }
    
}

extension ContactsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contactsToShow.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print(indexPath.row)
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactCell", for: indexPath) as! ContactsTableViewCell
        let index = indexPath.row
        let name = contactsToShow[index].firstName + " " + contactsToShow[index].lastName
        cell.createCell(with: ContactCell(name: name, image: images[index]))
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        set variable for contact head and id
        selectedContact = contactsToShow[indexPath.row]
        performSegue(withIdentifier: "goBackToChatsScreen", sender: self)
    }
}
