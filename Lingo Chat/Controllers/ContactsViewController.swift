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
    
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var noContactsLabel: UILabel!
    private var personalContacts = [String]()
    private var contactsToShow: [UserAccount] = []
    public var selectedContact: UserAccount!
    private var hasFetched = false
    private var images: [UIImage] = []
    private var searchContacts: [UserAccount] = []
    private var searchImages = [UIImage]()
    private var filtered = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        
        setupContactsData { [weak self] (success) in
            if success {
                self?.downloadImages { (_) in
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    private func setupViews() {
        setupLocalizationText()
        setupDelegates()
        searchField.setBottomBorder()
        searchField.addTarget(self, action: #selector(didbegin(_:)), for: .editingDidBegin)
        searchField.addTarget(self, action: #selector(endediting(_:)), for: .editingDidEnd)
        let icon = UIImage(systemName: "magnifyingglass")
        searchField.setLeftIcon(icon!)
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
    
    private func setupLocalizationText() {
        searchField.placeholder = NSLocalizedString("zWJ-Wc-7vS.placeholder", comment: "")
        noContactsLabel.text = NSLocalizedString("HXC-6H-hip.text", comment: "")
        cancelButton.setTitle(NSLocalizedString("R65-9X-KKN.title", comment: ""), for: .normal)
    }
    
    private func setupDelegates() {
        tableView.delegate = self
        tableView.dataSource = self
        searchField.delegate = self
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
        view.resignFirstResponder()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        searchField.resignFirstResponder()
    }
    

    @IBAction func cancelButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}


extension ContactsViewController: UITextFieldDelegate {
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        searchContacts.removeAll()
        searchImages.removeAll()
        tableView.reloadData()
        return true
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text {
            let query = text + string
            filterText(query)
        }
        return true
    }
    
    func filterText(_ query: String) {
        filtered = false
        searchContacts.removeAll()
        searchImages.removeAll()
        let text = query.lowercased()
        for i in 0..<contactsToShow.count {
            if contactsToShow[i].firstName.lowercased().contains(text) || contactsToShow[i].lastName.lowercased().contains(text) {
                searchContacts.append(contactsToShow[i])
                searchImages.append(images[i])
            }
            else {
                filtered = true
            }
        }
        tableView.reloadData()
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

extension ContactsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !searchContacts.isEmpty {
            return searchContacts.count
        }
        return filtered ? 0 : contactsToShow.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print(indexPath.row)
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactCell", for: indexPath) as! ContactsTableViewCell
        let index = indexPath.row
        if !searchContacts.isEmpty {
            let name = searchContacts[index].firstName + " " + searchContacts[index].lastName
            cell.createCell(with: ContactCell(name: name, image: searchImages[index]))
        }
        else {
            let name = contactsToShow[index].firstName + " " + contactsToShow[index].lastName
            cell.createCell(with: ContactCell(name: name, image: images[index]))
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        set variable for contact head and id
        if !searchContacts.isEmpty {
            selectedContact = searchContacts[indexPath.row]
        }
        else {
           selectedContact = contactsToShow[indexPath.row]
        }
        performSegue(withIdentifier: "goBackToChatsScreen", sender: self)
    }
}
