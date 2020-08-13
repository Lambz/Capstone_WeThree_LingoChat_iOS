//
//  ConversationViewController.swift
//  Lingo Chat
//
//  Created by Chetan on 2020-08-12.
//  Copyright © 2020 Chetan. All rights reserved.
//

import UIKit
import MessageKit

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
    var language: Int
}

class ConversationViewController: MessagesViewController {

    private var messages = [Message]()
    private var selfSender = Sender(photoURL: URL(fileURLWithPath: ""), senderId: "1", displayName: "Bob Smith", language: 1)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        messages.append(Message(sender: selfSender, messageId: "1", sentDate: Date(), kind: .text("Hello")))
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
    }
    
//    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapComposeMessage))
//    @objc func didtapComposeMessage(_ : UIBarButtonItem) {
//        
//    }


}

extension ConversationViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> SenderType {
        return selfSender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
}
