//
//  VideoViewController.swift
//  Lingo Chat
//
//  Created by Chetan on 2020-08-09.
//  Copyright © 2020 Chetan. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class VideoViewController: AVPlayerViewController {

    public var videoUrl: URL!
    override func viewDidLoad() {
        super.viewDidLoad()

        player = AVPlayer(url: videoUrl)
        player?.play()
    }
    
}
