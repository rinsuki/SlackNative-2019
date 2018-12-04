//
//  WebViewController.swift
//  SlackNative
//
//  Created by user on 2018/11/14.
//  Copyright © 2018 rinsuki. All rights reserved.
//

import Cocoa
import WebKit
import UserNotifications

class WebViewController: NSViewController {

    var webview: WKWebView!
    weak var tabViewItem: NSTabViewItem?
    
    enum ScriptHandlerName: String {
        case sendNotification
        case teamIconUrl
    }
    
    init(team: String) {
        super.init(nibName: nil, bundle: nil)

        let webviewConfig = WKWebViewConfiguration()
        
        // userAgent
        let safariBundle = Bundle(path: "/Applications/Safari.app")
        let version = safariBundle!.infoDictionary!["CFBundleShortVersionString"] as! String
        webviewConfig.applicationNameForUserAgent = "Version/\(version) Safari/605.1.15"
        
        // WebViewとネイティブの橋
        let userController = WKUserContentController()
        userController.add(self, name: ScriptHandlerName.sendNotification.rawValue)
        userController.add(self, name: ScriptHandlerName.teamIconUrl.rawValue)
        webviewConfig.userContentController = userController
        
        self.webview = WKWebView(frame: .zero, configuration: webviewConfig)
        webview.navigationDelegate = self

        let url = URL(string: "https://\(team).slack.com")!
        let urlRequest = URLRequest(url: url)
        webview.load(urlRequest)
        print("launched")

        self.view = webview
        self.webview.addObserver(self, forKeyPath: "title", options: .new, context: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath, let change = change else {
            return
        }
        switch keyPath {
        case "title":
            self.title = self.webview.title
            self.tabViewItem?.label = self.webview.title ?? ""
        default:
            print(keyPath)
        }
    }
}

extension WebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let name = ScriptHandlerName.init(rawValue: message.name) else {
            return
        }
        switch name {
        case .sendNotification:
            let title = message.body as! [String?]
            print(title)
            let notify = UNMutableNotificationContent()
            notify.title = title[0] ?? ""
            notify.subtitle = title[1] ?? ""
            notify.body = title[2] ?? ""
            print(notify)
            let request = UNNotificationRequest(identifier: "", content: notify, trigger: nil)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        case .teamIconUrl:
            let urlString = message.body as! String
            print(urlString)
            let url = URL(string: urlString)!
            let image = NSImage(contentsOf: url)
            self.tabViewItem?.image = image
        }
    }
}

extension WebViewController: WKUIDelegate {
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        webview.evaluateJavaScript("""
window.addEventListener('DOMContentLoaded', () => {
    // やたら太くなるフォント君対策
    document.body.style.fontFamily='NotoSansJP,Slack-Lato,appleLogo,\"ヒラギノ角ゴ ProN\",sans-serif'

    // Notification API hack
    const base = window.Notification
    window.Notification = new Proxy(Notification, {
        get(target, name) {
            console.log(target, name)
            if (name === "permission") return "granted"
            return target[name]
        },
        construct(target, args) {
            console.log("notify", args)
            const params = args[1] || {}
            webkit.messageHandlers.sendNotification.postMessage([args[0], location.hostname, args[1]["body"], undefined])
            return new base(...args)
        }
    })
    if (window.boot_data && window.boot_data.api_token) {
        // チームアイコン取得
        const formData = new FormData()
        formData.append("token", window.boot_data.api_token)
        fetch("/api/team.info", {
            method: "POST",
            body: formData,
        }).then(res => res.json()).then(res => {
            if (!res.ok) return
            if (!res.team.icon.image_original) return
            webkit.messageHandlers.teamIconUrl.postMessage(res.team.icon.image_original)
        }).catch(e => console.error)
    }
})
""")
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        if navigationAction.navigationType == .linkActivated, !(navigationAction.targetFrame?.isMainFrame ?? false) {
            do {
                try NSWorkspace.shared.open(url, options: NSWorkspace.LaunchOptions.default, configuration: [:])
                decisionHandler(.cancel)
            } catch {
                decisionHandler(.allow)
            }
            return
        }
        decisionHandler(.allow)
    }
}
