//
//  ConversationViewController.swift
//  Lingo Chat
//
//  Created by Chetan on 2020-08-12.
//  Copyright © 2020 Chetan. All rights reserved.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage

struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
}

extension MessageKind {
    var messageKindString: String {
        switch self {
        case .text(_):
            return "text"
        case .photo(_):
            return "image"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .audio(_):
            return "audio"
        default: return "other"
        }
    }
}

struct Sender: SenderType {
    var photoURL: URL
    var senderId: String
    var displayName: String
    var language: String
}

struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}

class ConversationViewController: MessagesViewController {
    
    private var messages = [Message]()
    private var selfSender: Sender? {
        guard let image = UserDefaults.standard.object(forKey: "image") as? String, let id = UserDefaults.standard.object(forKey: "user_id") as? String, let firstName = UserDefaults.standard.object(forKey: "first_name") as? String, let lastName = UserDefaults.standard.object(forKey: "last_name") as? String, let language = UserDefaults.standard.object(forKey: "language") as? String else {
            return nil
        }
        return Sender(photoURL: URL(string: image)!, senderId: id, displayName: "\(firstName) \(lastName)", language: language)
    }
    
    private var talkingToSender: Sender!
    private var imagePickerController: UIImagePickerController?
    private var imageUrl: URL!
    
//    values to be passed through segues
    public var isNewConversation = false
    public var otherUser: UserAccount!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupDelegates()
        setupMessageBarView()
        fetchOtherUserIdAndSetupSender { [weak self] (success) in
            guard let strongSelf = self else {
                return
            }
            if success {
                DatabaseManager.shared.checkIfMessageExists(user: strongSelf.selfSender!.senderId, otherUser: strongSelf.talkingToSender.senderId) { (success) in
                    if success {
                        strongSelf.setupChatsListener()
                    }
                    else {
                        strongSelf.messages.removeAll()
                        strongSelf.messagesCollectionView.reloadDataAndKeepOffset()
                    }
                }
                
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    private func setupDelegates() {
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
    }
    
    private func setupMessageBarView() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "photo"), for: .normal)
        button.onTouchUpInside { [weak self] (_) in
            self?.mediaButtonTapped()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func mediaButtonTapped() {
        let actionSheet = UIAlertController(title: "Send media", message: "What would you like to send", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] (action) in
            self?.presentPhotoActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { (action) in
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }
    
    private func fetchOtherUserIdAndSetupSender(completion: @escaping(Bool) -> Void) {
        DatabaseManager.shared.getUserIdFromEmail(email: otherUser.email) { [weak self] (result) in
            guard let strongSelf = self else {
                completion(false)
                return
            }
            switch result {
            case .success(let id):
                strongSelf.talkingToSender = Sender(photoURL: URL(string: "image")!, senderId: id, displayName: "\(strongSelf.otherUser.firstName) \(strongSelf.otherUser.lastName)", language: (strongSelf.otherUser.language))
                completion(true)
            case .failure(let error):
                print("User ID can't be fetched: \(error)")
                completion(false)
            }
        }
    }
    
    
    private func setupChatsListener() {
        guard let sender = selfSender else {
            return
        }
        DatabaseManager.shared.getAllMessagesForConversation(user: sender, with: talkingToSender) { [weak self] (result) in
            guard let strongSelf = self else {
                return
            }
            print("Chat listener called")
            switch result {
            case .success(let messageList):
                if messageList.isEmpty {
                    print("message list empty")
                    strongSelf.messages.removeAll()
                    strongSelf.messagesCollectionView.reloadDataAndKeepOffset()
                    strongSelf.messagesCollectionView.scrollToBottom(animated: true)
                    return
                }
                else {
                DispatchQueue.main.async {
                    print("messagelist not empty")
                    strongSelf.messages = messageList
                    strongSelf.messagesCollectionView.reloadDataAndKeepOffset()
                    strongSelf.messagesCollectionView.scrollToBottom(animated: true)
                }
                
                }
                
            case .failure(let error):
                print("Error while fetching messages: \(error)")
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is PhotoViewController {
            if let destVC = segue.destination as? PhotoViewController {
                destVC.title = "Sent by \(talkingToSender.displayName)"
                destVC.imageUrl = imageUrl
            }
        }
        
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
            
            if action == NSSelectorFromString("delete:") {
                return true
            } else {
                return super.collectionView(collectionView, canPerformAction: action, forItemAt: indexPath, withSender: sender)
            }
        }
        
    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        
        if action == NSSelectorFromString("delete:") {
            let index = messages.count - indexPath.row - 1
            showDeleteAlert(index: index)
        } else {
            super.collectionView(collectionView, performAction: action, forItemAt: indexPath, withSender: sender)
        }
    }
    
    private func showDeleteAlert(index: Int) {
        let alert = UIAlertController(title: "Delete message", message: "Delete mesage for?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Only me", style: .default, handler: { [weak self] (_) in
            self?.deleteMessageForUser(index: index)
        }))
        alert.addAction(UIAlertAction(title: "Everyone", style: .default, handler: { [weak self] (_) in
            self?.deleteMessageForEveryone(index: index)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    private func deleteMessageForUser(index: Int) {
        DatabaseManager.shared.deleteMessageForUser(messageId: messages[index].messageId, otherUserId: talkingToSender.senderId) { [weak self] (success) in
            if success {
                self?.messagesCollectionView.reloadDataAndKeepOffset()
            }
        }
    }
    
    private func deleteMessageForEveryone(index: Int) {
        DatabaseManager.shared.deleteMessageForEveryone(messageId: messages[index].messageId, otherUserId: talkingToSender.senderId) { [weak self] (success) in
            if success {
                self?.messagesCollectionView.reloadDataAndKeepOffset()
            }
        }
    }
    
}


extension ConversationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func presentPhotoActionSheet() {
        if self.imagePickerController != nil {
            self.imagePickerController?.delegate = nil
            self.imagePickerController = nil
        }
        
        self.imagePickerController = UIImagePickerController.init()
        
        let alert = UIAlertController.init(title: "Select Source Type", message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction.init(title: "Camera", style: .default, handler: { (_) in
                self.showCamera()
            }))
        }
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alert.addAction(UIAlertAction.init(title: "Photo Library", style: .default, handler: { (_) in
                self.showGallery()
            }))
        }
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel))
        
        self.present(alert, animated: true)
    }
    
    func showCamera() {
        imagePickerController = UIImagePickerController()
        imagePickerController!.sourceType = .camera
        imagePickerController!.delegate = self
        imagePickerController!.allowsEditing = true
        self.present(imagePickerController!, animated: true)
    }
    
    func showGallery() {
        imagePickerController = UIImagePickerController()
        imagePickerController!.sourceType = .photoLibrary
        imagePickerController!.delegate = self
        imagePickerController!.allowsEditing = true
        self.present(imagePickerController!, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            return
        }
        guard let data = selectedImage.jpegData(compressionQuality: 1.0) else {
            return
        }
        let randomId = DatabaseManager.shared.generateRandomId()
        let fileName = "\(randomId).jpeg"
        StorageManager.shared.uploadMessagePicture(with: data, fileName: fileName) { [weak self](result) in
            switch result {
            case .failure(let error):
                print("Storage manager insertion error: \(error)")
            case .success(let url):
                self?.sendMessageWithImage(with: url, id: randomId)
            }
        }
        
        picker.dismiss(animated: true) {
            picker.delegate = nil
            self.imagePickerController = nil
        }
    }
    
    private func sendMessageWithImage(with: String, id: String) {
        guard let sender = selfSender else {
            return
        }
        let message = Message(sender: sender, messageId: id, sentDate: Date(), kind: .photo(Media(url: URL(string: with), image: nil, placeholderImage: UIImage(named: "user")!, size: .zero)))
        
        DatabaseManager.shared.sendMesage(to: talkingToSender.senderId, message: message, randomID: id) { (success) in
            if success {
                print("Image sent")
            }
            else {
                print("Error sending image")
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) {
            picker.delegate = nil
            self.imagePickerController = nil
        }
    }
}


//MARK: input bar methods implemented
extension ConversationViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        let message = Message(sender: selfSender!, messageId: "messageId", sentDate: Date(), kind: .text(text))
        inputBar.inputTextView.text = ""
        let id = DatabaseManager.shared.generateRandomId()
        DatabaseManager.shared.sendMesage(to: talkingToSender.senderId, message: message, randomID: id) { (success) in
            if !success {
                inputBar.inputTextView.text = text
            }
        }
        
    }
}


//MARK: message list view methods implemented
extension ConversationViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        return Sender(photoURL: URL(string: "dummy")!, senderId: "dummy", displayName: "dummy", language: "dummy")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        switch message.kind {
        case .photo(let media):
            guard let url = media.url else {
                return
            }
            imageView.sd_setImage(with: url, completed: nil)
        default: break
        }
    }
    
}

extension ConversationViewController: MessageCellDelegate {
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        switch message.kind {
        case .photo(let media):
            guard media.url != nil else {
                return
            }
            imageUrl = media.url
            self.performSegue(withIdentifier: "gotoPhotoScreen", sender: self)
        default: break
        }
    }
    
    
}

extension MessageCollectionViewCell {

    override open func delete(_ sender: Any?) {
        
        // Get the collectionView
        if let collectionView = self.superview as? UICollectionView {
            // Get indexPath
            if let indexPath = collectionView.indexPath(for: self) {
                // Trigger action
                collectionView.delegate?.collectionView?(collectionView, performAction: NSSelectorFromString("delete:"), forItemAt: indexPath, withSender: sender)
            }
        }
    }
}
