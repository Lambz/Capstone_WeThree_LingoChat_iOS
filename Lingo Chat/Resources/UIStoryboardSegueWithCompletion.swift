//
//  UIStoryboardSegueWithCompletion.swift
//  Lingo Chat
//
//  Created by Chetan on 2020-08-17.
//  Copyright © 2020 Chetan. All rights reserved.
//

import UIKit

class UIStoryboardSegueWithCompletion: UIStoryboardSegue {
    var completion: (() -> Void)?

    override func perform() {
        super.perform()
        if let completion = completion {
            completion()
        }
    }
}
