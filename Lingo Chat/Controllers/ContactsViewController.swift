//
//  ContactsViewController.swift
//  Lingo Chat
//
//  Created by Chetan on 2020-08-09.
//  Copyright © 2020 Chetan. All rights reserved.
//

import UIKit
import JGProgressHUD

class ContactsViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
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
        setupDelegates()
        setupContactsData()
    }
    
    private func setupDelegates() {
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        searchBar.becomeFirstResponder()
        tableView.isHidden = true
        noContactsLabel.isHidden = true
    }
    
    private func setupContactsData() {
        personalContacts = ContactsHelper.fetchContacts()
                if !personalContacts.isEmpty {
                    print("Phone contacts fetched")
                    spinner.show(in: view)
                    personalContacts = personalContacts.map{$0.lowercased()}
                    fetchContacts { (result) in
                        print("contacts fetched")
                        self.spinner.dismiss()
                        
                        switch result {
                        case .success(let isNotEmpty):
                            if isNotEmpty {
        //                        refresh view
                                self.tableView.isHidden = false
                                self.spinner.show(in: self.view)
                                self.downloadImages { (_) in
                                    print("images downloaded")
                                    self.spinner.dismiss()
                                    self.tableView.reloadData()
                                }
                            }
                            else {
                                self.noContactsLabel.isHidden = false
                                
                            }
                        case .failure(let error):
                            print("Failed to fetch contacts: \(error)")
                        }
                    }
                }
    }
    
    private func downloadImages(completion: @escaping(Bool)->Void) {
        for contact in contactsToShow {
            do
            {
                let data = try Data.init(contentsOf: URL(string: contact.image)!)
                images.append(UIImage(data: data)!)
            }
            catch {
                print("image data could not be downloaded for list")
                images.append(UIImage(named: "user")!)
            }
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
        print("called")
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
