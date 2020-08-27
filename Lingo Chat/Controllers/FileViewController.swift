//
//  FileViewController.swift
//  Lingo Chat
//
//  Created by Chetan on 2020-08-26.
//  Copyright © 2020 Chetan. All rights reserved.
//

import UIKit
import PDFKit

class FileViewController: UIViewController {

    public var documentUrl: URL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
         let pdfView: PDFView = PDFView(frame: self.view.frame)
        pdfView.document = PDFDocument(url: documentUrl)
        self.view.addSubview(pdfView)
    }
    
}
