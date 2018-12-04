//
//  ViewController.swift
//  SlackNative
//
//  Created by user on 2018/11/14.
//  Copyright © 2018 rinsuki. All rights reserved.
//

import Cocoa
import WebKit
import UserNotifications

class ViewController: NSViewController {

//    let tabView = NSTabView()
//    let teamsSelector = NSTableView()
    @IBOutlet weak var tabView: NSTabView!
    @IBOutlet weak var teamsSelector: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for team in UserDefaults.standard.object(forKey: "teams") as? [String] ?? [] {
            tabView.addTabViewItem(self.getTabItem(team: team))
        }
        let newTabC = NewTabViewController()
        newTabC.addCallback = { teamName in
            let pos = self.tabView.tabViewItems.count - 1
            self.tabView.insertTabViewItem(self.getTabItem(team: teamName), at: pos)
            self.tabView.selectTabViewItem(at: pos)
            var teams = UserDefaults.standard.object(forKey: "teams") as? [String] ?? []
            teams.append(teamName)
            UserDefaults.standard.set(teams, forKey: "teams")
        }
        let newTabViewItem = NSTabViewItem(viewController: newTabC)
        newTabViewItem.label = "New Tab"
        newTabViewItem.image = NSImage(named: "addButton")
        tabView.addTabViewItem(newTabViewItem)
        teamsSelector.dataSource = self
        teamsSelector.delegate = self
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let tabViewItem = object as? NSTabViewItem {
            if tabViewItem.tabState == .selectedTab {
                self.view.window?.title = tabViewItem.label
            }
            self.teamsSelector.reloadData()
        }
        print(keyPath, object)
    }
    
    func getTabItem(team: String) -> NSTabViewItem {
        let webview = WebViewController(team: team)
        let tabViewItem = NSTabViewItem(viewController: webview)
        tabViewItem.label = ""
        tabViewItem.addObserver(self, forKeyPath: "label", options: .new, context: nil)
        tabViewItem.addObserver(self, forKeyPath: "image", options: .new, context: nil)
        webview.tabViewItem = tabViewItem
        return tabViewItem
    }
}

extension ViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.tabView.tabViewItems.count
    }
}

extension ViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "team"), owner: self) as! TeamCellView
        view.iconView.image = self.tabView.tabViewItems[row].image
        return view
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = self.teamsSelector.selectedRow
        self.tabView.selectTabViewItem(at: row)
        self.view.window?.title = self.tabView.tabViewItem(at: row).label
    }
}

class TeamCellView: NSTableCellView {
    @IBOutlet weak var iconView: NSImageView!
    
}
