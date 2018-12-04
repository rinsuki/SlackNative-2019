//
//  NewTabViewController.swift
//  SlackNative
//
//  Created by user on 2018/11/14.
//  Copyright © 2018 rinsuki. All rights reserved.
//

import Cocoa

class NewTabViewController: NSViewController {
    @IBOutlet weak var teamNameField: NSTextField!
    var addCallback: (( String) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func clickAddButton(_ sender: Any) {
        let teamName = self.teamNameField.stringValue
        self.teamNameField.stringValue = ""
        self.addCallback?(teamName)
    }
}
