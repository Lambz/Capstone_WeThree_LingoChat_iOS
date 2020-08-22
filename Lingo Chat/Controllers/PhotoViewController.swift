//
//  PhotoViewerViewController.swift
//  Lingo Chat
//
//  Created by Chetan on 2020-08-09.
//  Copyright © 2020 Chetan. All rights reserved.
//

import UIKit
import SDWebImage

class PhotoViewController: UIViewController {

    
    @IBOutlet weak var imageViewer: UIImageView!
    public var imageUrl: URL!
    override func viewDidLoad() {
        super.viewDidLoad()
        imageViewer.sd_setImage(with: imageUrl, completed: nil)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
}
