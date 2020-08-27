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
import CoreLocation
import MobileCoreServices
import SafariServices

struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    var language: String
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
        case .attributedText(_):
            return "pdf"
        default: return "default"
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

struct Location: LocationItem {
    var location: CLLocation
    var size: CGSize
}

class ConversationViewController: MessagesViewController {
    
    public var latitude: Double!
    public var longitude: Double!
    private var isOldLocation = false
    
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
    private var videoUrl: URL!
    private var documentUrl: URL!
    
//    values to be passed through segues
    public var isNewConversation = false
    public var otherUser: UserAccount!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.isHidden = true
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
        messageInputBar.inputTextView.resignFirstResponder()
    }
    
    @IBAction func unwindFromMap(segue: UIStoryboardSegue) {
        guard let sender = selfSender else {
            return
        }
        let location = Location(location: CLLocation(latitude: latitude, longitude: longitude), size: .zero)
        let id = DatabaseManager.shared.generateRandomId()
        let message = Message(sender: sender, messageId: id, sentDate: Date(), kind: .location(location), language: sender.language)
        DatabaseManager.shared.sendMesage(to: talkingToSender.senderId, message: message, randomID: id) { (_) in
            
        }
        
    }
    
     @IBAction func unwindFromFileScreen(segue: UIStoryboardSegue) {
        
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
        button.setImage(UIImage(systemName: "link"), for: .normal)
        button.onTouchUpInside { [weak self] (_) in
            self?.mediaButtonTapped()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func mediaButtonTapped() {
        let actionSheet = UIAlertController(title: NSLocalizedString("SendMedia", comment: ""), message: NSLocalizedString("SendMediaMessage", comment: ""), preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: NSLocalizedString("Photo", comment: ""), style: .default, handler: { [weak self] (action) in
            self?.presentPhotoActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: NSLocalizedString("Video", comment: ""), style: .default, handler: { [weak self] (action) in
            self?.presentVideoActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: NSLocalizedString("Location", comment: ""), style: .default, handler: { [weak self] (action) in
            self?.presentLocationPicker()
        }))
        actionSheet.addAction(UIAlertAction(title: NSLocalizedString("Document", comment: ""), style: .default, handler: { [weak self] (action) in
            self?.presentDocumentPicker()
        }))
        actionSheet.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }
    
    private func presentLocationPicker() {
        self.performSegue(withIdentifier: "showMapScreen", sender: self)
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
                destVC.title = NSLocalizedString("ChatWith", comment: "") + " \(talkingToSender.displayName)"
                destVC.imageUrl = imageUrl
            }
        }
        
        if segue.destination is LocationViewController {
            if isOldLocation {
                isOldLocation = false
                if let destVC = segue.destination as? LocationViewController {
                    destVC.selectedLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                }
            }
        }
        
        if segue.destination is VideoViewController {
            if let destVC = segue.destination as? VideoViewController {
                destVC.title = NSLocalizedString("ChatWith", comment: "") + " \(talkingToSender.displayName)"
                destVC.videoUrl = videoUrl
            }
            
        }
        
        if segue.destination is FileViewController {
            if let destVC = segue.destination as? FileViewController {
                destVC.title = NSLocalizedString("Document", comment: "")
                destVC.documentUrl = documentUrl
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
            let message = messageForItem(at: indexPath, in: messagesCollectionView)
            if message.sender.senderId == selfSender?.senderId {
                showDeleteAlert(index: index, show: true)
            }
            else {
                showDeleteAlert(index: index, show: false)
            }
        } else {
            super.collectionView(collectionView, performAction: action, forItemAt: indexPath, withSender: sender)
        }
    }
    
    private func showDeleteAlert(index: Int, show: Bool) {
        let alert = UIAlertController(title: NSLocalizedString("DeleteMessage?", comment: ""), message: NSLocalizedString("DeleteMsg", comment: ""), preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OnlyMe", comment: ""), style: .default, handler: { [weak self] (_) in
            self?.deleteMessageForUser(index: index)
        }))
        if show {
            alert.addAction(UIAlertAction(title: NSLocalizedString("Everyone", comment: ""), style: .default, handler: { [weak self] (_) in
                self?.deleteMessageForEveryone(index: index)
            }))
        }
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
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
        
        let alert = UIAlertController.init(title: NSLocalizedString("SelectSource", comment: ""), message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction.init(title: NSLocalizedString("Camera", comment: ""), style: .default, handler: { (_) in
                self.showCamera(video: false)
            }))
        }
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alert.addAction(UIAlertAction.init(title: NSLocalizedString("PhotoLibrary", comment: ""), style: .default, handler: { (_) in
                self.showGallery(video: false)
            }))
        }
        
        alert.addAction(UIAlertAction.init(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
        
        self.present(alert, animated: true)
    }
    
    private func presentVideoActionSheet() {
        if self.imagePickerController != nil {
            self.imagePickerController?.delegate = nil
            self.imagePickerController = nil
        }
        
        self.imagePickerController = UIImagePickerController.init()
        
        let alert = UIAlertController.init(title: NSLocalizedString("SelectSource", comment: ""), message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction.init(title: NSLocalizedString("Camera", comment: ""), style: .default, handler: { (_) in
                self.showCamera(video: true)
            }))
        }
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alert.addAction(UIAlertAction.init(title: NSLocalizedString("VideoLibrary", comment: ""), style: .default, handler: { (_) in
                self.showGallery(video: true)
            }))
        }
        
        alert.addAction(UIAlertAction.init(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
        
        self.present(alert, animated: true)
    }
    
    
    
    func showCamera(video: Bool) {
        imagePickerController = UIImagePickerController()
        imagePickerController!.sourceType = .camera
        imagePickerController!.delegate = self
        imagePickerController!.allowsEditing = true
        if video {
            imagePickerController!.mediaTypes = ["public.movie"]
            imagePickerController!.videoQuality = .typeMedium
        }
        self.present(imagePickerController!, animated: true)
    }
    
    func showGallery(video: Bool) {
        imagePickerController = UIImagePickerController()
        imagePickerController!.sourceType = .photoLibrary
        imagePickerController!.delegate = self
        imagePickerController!.allowsEditing = true
        if video {
            imagePickerController!.mediaTypes = ["public.movie"]
            imagePickerController!.videoQuality = .typeMedium
        }
        self.present(imagePickerController!, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        print("function called")
        let randomId = DatabaseManager.shared.generateRandomId()
        if let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage, let data = selectedImage.jpegData(compressionQuality: 1.0) {
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
        else if let videoUrl = info[.mediaURL] as? URL {
            print("Reched before saving")
            let fileName = "\(randomId).mov"
            StorageManager.shared.uploadMessageVideo(with: videoUrl, fileName: fileName) { [weak self](result) in
                print("Insertion done")
                switch result {
                case .failure(let error):
                    print("Storage manager insertion error: \(error)")
                case .success(let url):
                    self?.sendMessageWithVideo(with: url, id: randomId)
                }
            }
            
            picker.dismiss(animated: true) {
                picker.delegate = nil
                self.imagePickerController = nil
            }
        }
    
        
        
    }
    
    private func sendMessageWithImage(with: String, id: String) {
        guard let sender = selfSender else {
            return
        }
        let message = Message(sender: sender, messageId: id, sentDate: Date(), kind: .photo(Media(url: URL(string: with), image: nil, placeholderImage: UIImage(named: "user")!, size: .zero)), language: "")
        
        DatabaseManager.shared.sendMesage(to: talkingToSender.senderId, message: message, randomID: id) { (success) in
            if success {
                print("Image sent")
            }
            else {
                print("Error sending image")
            }
        }
    }
    
    private func sendMessageWithVideo(with: String, id: String) {
           guard let sender = selfSender else {
               return
           }
           let message = Message(sender: sender, messageId: id, sentDate: Date(), kind: .video(Media(url: URL(string: with), image: nil, placeholderImage: UIImage(named: "user")!, size: .zero)), language: "")
           
           DatabaseManager.shared.sendMesage(to: talkingToSender.senderId, message: message, randomID: id) { (success) in
               if success {
                   print("Video sent")
               }
               else {
                   print("Error sending video")
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
        let message = Message(sender: selfSender!, messageId: "messageId", sentDate: Date(), kind: .text(text), language: "")
        inputBar.inputTextView.text = ""
        let id = DatabaseManager.shared.generateRandomId()
        DatabaseManager.shared.sendMesage(to: talkingToSender.senderId, message: message, randomID: id) { (success) in
            if !success {
                inputBar.inputTextView.text = text
            }
        }
        
    }
}


extension ConversationViewController: UIDocumentPickerDelegate {
    
    private func presentDocumentPicker() {
           let types = [kUTTypePDF]
           let importMenu = UIDocumentPickerViewController(documentTypes: types as [String], in: .import)
//           importMenu.allowsMultipleSelection = true
           importMenu.delegate = self
//           importMenu.modalPresentationStyle = .formSheet

           present(importMenu, animated: true)
       }
        
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
//        viewModel.attachDocuments(at: urls)
        let id = DatabaseManager.shared.generateRandomId()
        let fileName = "\(id).pdf"
        StorageManager.shared.uploadMessageFile(with: urls[0], fileName: fileName) { [weak self] (result) in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .failure(let error):
                print(error)
            case .success(let url):
                let message = Message(sender: strongSelf.selfSender!, messageId: id, sentDate: Date(), kind: .attributedText(NSAttributedString(string: url)), language: strongSelf.selfSender!.language)
                DatabaseManager.shared.sendMesage(to: strongSelf.talkingToSender.senderId, message: message, randomID: id) { (_) in
                    
                }
            }
        }
        
    }

     func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true, completion: nil)
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
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        if message.sender.senderId == selfSender?.senderId {
            return .systemBlue
        }
        return .secondarySystemBackground
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        if message.sender.senderId == self.selfSender?.senderId {
            let url = URL(string: UserDefaults.standard.object(forKey: "image") as! String)
            avatarView.sd_setImage(with: url, completed: nil)
        }
        else {
            DatabaseManager.shared.fetchImageUrlFromId(id: talkingToSender.senderId) { (result) in
                switch result {
                    case .success(let url):
                        avatarView.sd_setImage(with: URL(string: url), completed: nil)
                case .failure(_):
                    print("Error fetching image")
                }
            }
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
        case .video(let media):
            guard media.url != nil else {
                return
            }
            videoUrl = media.url
            self.performSegue(withIdentifier: "gotoVideoScreen", sender: self)
        default: break
        }
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        switch message.kind {
        case .location(let location):
            latitude = location.location.coordinate.latitude
            longitude = location.location.coordinate.longitude
            isOldLocation = true
            self.performSegue(withIdentifier: "showMapScreen", sender: self)
        case .attributedText(let string):
            documentUrl = URL(string: string.string)
            performSegue(withIdentifier: "showFileScreen", sender: self)
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
