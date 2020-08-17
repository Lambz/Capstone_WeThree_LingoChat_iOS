//
//  ContactsTableViewCell.swift
//  Lingo Chat
//
//  Created by Chetan on 2020-08-16.
//  Copyright © 2020 Chetan. All rights reserved.
//

import UIKit

class ContactsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var contactImage: UIImageView!
    
    @IBOutlet weak var contactName: UILabel!
    
    func createCell(with contact: ContactCell) {
        contactImage.image = contact.image
        contactName.text = contact.name
    }
}

struct ContactCell {
    let name: String
    let image: UIImage
}
