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

struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
}

struct Sender: SenderType {
    var photoURL: URL
    var senderId: String
    var displayName: String
    var language: String
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
//    values to be passed through segues
    public var isNewConversation = false
    public var otherUser: UserAccount!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupDelegates()
        fetchOtherUserIdAndSetupSender()
        
        
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
        messageInputBar.delegate = self
    }
    
    private func fetchOtherUserIdAndSetupSender() {
        DatabaseManager.shared.getUserIdFromEmail(email: otherUser.email) { (result) in
            switch result {
            case .success(let id):
                self.talkingToSender = Sender(photoURL: URL(string: self.otherUser.image)!, senderId: id, displayName: "\(self.otherUser.firstName) \(self.otherUser.lastName)", language: self.otherUser.language)
            case .failure(let error):
                print("User ID can't be fetched: \(error)")
            }
        }
    }

}

extension ConversationViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        if isNewConversation {
            
        }
        else {
            
        }
    }
}




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
    
    
}
