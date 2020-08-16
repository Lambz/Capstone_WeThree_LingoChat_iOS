//
//  SettingsTableViewCell.swift
//  Lingo Chat
//
//  Created by Chetan on 2020-08-15.
//  Copyright © 2020 Chetan. All rights reserved.
//

import UIKit

class SettingsTableViewCell: UITableViewCell {

    
    @IBOutlet weak var settingsIconView: UIImageView!
    
    @IBOutlet weak var settingsTextLabel: UILabel!
    
    
    func createSettingsCell(cell: SettingsTableCell) {
        settingsIconView.image = cell.image
        settingsTextLabel.text = cell.text
    }
    
}

struct SettingsTableCell {
    let image: UIImage
    let text: String
}
