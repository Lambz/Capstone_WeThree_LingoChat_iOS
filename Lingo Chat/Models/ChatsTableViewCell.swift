//
//  ChatsTableViewCell.swift
//  Lingo Chat
//
//  Created by Chetan on 2020-08-12.
//  Copyright © 2020 Chetan. All rights reserved.
//

import UIKit

class ChatsTableViewCell: UITableViewCell {

    @IBOutlet weak var cellImage: UIImageView!
    
    @IBOutlet weak var senderNameLabel: UILabel!
    
    @IBOutlet weak var lastConversationLabel: UILabel!
    
    func createChatCell(image: UIImage, senderName: String, lastMsg: String) {
        
    }
    
}


struct chatTableCellItem {
    let senderName: String
    let lastMessage: String
    let image: UIImage
}
