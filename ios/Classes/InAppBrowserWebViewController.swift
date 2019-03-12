//
//  InAppBrowserWebViewController.swift
//  flutter_inappbrowser
//
//  Created by Lorenzo on 17/09/18.
//

import Flutter
import UIKit
import WebKit
import Foundation
import AVFoundation

typealias OlderClosureType =  @convention(c) (Any, Selector, UnsafeRawPointer, Bool, Bool, Any?) -> Void
typealias NewerClosureType =  @convention(c) (Any, Selector, UnsafeRawPointer, Bool, Bool, Bool, Any?) -> Void

//extension WKWebView{
//
//    var keyboardDisplayRequiresUserAction: Bool? {
//        get {
//            return self.keyboardDisplayRequiresUserAction
//        }
//        set {
//            self.setKeyboardRequiresUserInteraction(newValue ?? true)
//        }
//    }
//
//    func setKeyboardRequiresUserInteraction( _ value: Bool) {
//
//        guard
//            let WKContentViewClass: AnyClass = NSClassFromString("WKContentView") else {
//                print("Cannot find the WKContentView class")
//                return
//        }
//
//        let olderSelector: Selector = sel_getUid("_startAssistingNode:userIsInteracting:blurPreviousNode:userObject:")
//        let newerSelector: Selector = sel_getUid("_startAssistingNode:userIsInteracting:blurPreviousNode:changingActivityState:userObject:")
//
//        if let method = class_getInstanceMethod(WKContentViewClass, olderSelector) {
//
//            let originalImp: IMP = method_getImplementation(method)
//            let original: OlderClosureType = unsafeBitCast(originalImp, to: OlderClosureType.self)
//            let block : @convention(block) (Any, UnsafeRawPointer, Bool, Bool, Any?) -> Void = { (me, arg0, arg1, arg2, arg3) in
//                original(me, olderSelector, arg0, !value, arg2, arg3)
//            }
//            let imp: IMP = imp_implementationWithBlock(block)
//            method_setImplementation(method, imp)
//        }
//
//        if let method = class_getInstanceMethod(WKContentViewClass, newerSelector) {
//
//            let originalImp: IMP = method_getImplementation(method)
//            let original: NewerClosureType = unsafeBitCast(originalImp, to: NewerClosureType.self)
//            let block : @convention(block) (Any, UnsafeRawPointer, Bool, Bool, Bool, Any?) -> Void = { (me, arg0, arg1, arg2, arg3, arg4) in
//                original(me, newerSelector, arg0, !value, arg2, arg3, arg4)
//            }
//            let imp: IMP = imp_implementationWithBlock(block)
//            method_setImplementation(method, imp)
//        }
//
//    }
//
//}

class InAppWebView_IBWrapper: InAppWebView {
    required convenience init(coder: NSCoder) {
        let config = WKWebViewConfiguration()
        self.init(frame: .zero, configuration: config, IABController: nil, IAWController: nil)
        self.translatesAutoresizingMaskIntoConstraints = false
    }
}

class InAppBrowserWebViewController: UIViewController, UIScrollViewDelegate, WKUIDelegate, UITextFieldDelegate {
    
    @IBOutlet var webView: InAppWebView_IBWrapper!
    @IBOutlet var closeButton: UIButton!
    @IBOutlet var reloadButton: UIBarButtonItem!
    @IBOutlet var backButton: UIBarButtonItem!
    @IBOutlet var forwardButton: UIBarButtonItem!
    @IBOutlet var shareButton: UIBarButtonItem!
    @IBOutlet var spinner: UIActivityIndicatorView!
    @IBOutlet var toolbarTop: UIView!
    @IBOutlet var toolbarBottom: UIToolbar!
    @IBOutlet var urlField: UITextField!
    
    @IBOutlet var toolbarTop_BottomToWebViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var toolbarBottom_TopToWebViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var webView_BottomFullScreenConstraint: NSLayoutConstraint!
    @IBOutlet var webView_TopFullScreenConstraint: NSLayoutConstraint!
    
    weak var navigationDelegate: SwiftFlutterPlugin?
    var initURL: URL?
    var tmpWindow: UIWindow?
    var browserOptions: InAppBrowserOptions?
    var webViewOptions: InAppWebViewOptions?
    var initHeaders: [String: String]?
    var initData: String?
    var initMimeType: String?
    var initEncoding: String?
    var initBaseUrl: String?
    var isHidden = false
    var uuid: String = ""
    var WKNavigationMap: [String: [String: Any]] = [:]
    var startPageTime: Int64 = 0
    var viewPrepared = false
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.webView.IABController = self
        if !viewPrepared {
            prepareConstraints()
            prepareWebView()
        }
        viewPrepared = true
        super.viewWillAppear(animated)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        webView.uiDelegate = self
//        webView.navigationDelegate = nil
//        webView.scrollView.delegate = self
        
        urlField.delegate = self
        urlField.text = self.initURL?.absoluteString
        
        closeButton.addTarget(self, action: #selector(self.close), for: .touchUpInside)
        
        forwardButton.target = self
        forwardButton.action = #selector(self.goForward)
        
        forwardButton.target = self
        forwardButton.action = #selector(self.goForward)
        
        backButton.target = self
        backButton.action = #selector(self.goBack)
        
        reloadButton.target = self
        reloadButton.action = #selector(self.reload)
        
        shareButton.target = self
        shareButton.action = #selector(self.share)
        
        spinner.hidesWhenStopped = true
        spinner.isHidden = false
        spinner.stopAnimating()
        
        if self.initData == nil {
            loadUrl(url: self.initURL!, headers: self.initHeaders)
        }
        else {
            webView.loadData(data: initData!, mimeType: initMimeType!, encoding: initEncoding!, baseUrl: initBaseUrl!)
        }
        
        navigationDelegate?.onBrowserCreated(uuid: uuid, webView: webView)
    }
    
    // Prevent crashes on closing windows
    deinit {
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
        webView.uiDelegate = nil
    }
    
    override func viewWillDisappear (_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func prepareConstraints () {
        webView_BottomFullScreenConstraint = NSLayoutConstraint(item: self.webView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0)
        webView_TopFullScreenConstraint = NSLayoutConstraint(item: self.webView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0)
    }
    
    func prepareWebView() {
        //UIApplication.shared.statusBarStyle = preferredStatusBarStyle
        
        self.webView.options = webViewOptions
        self.webView.prepare()
        
        if (browserOptions?.hideUrlBar)! {
            self.urlField.isHidden = true
            self.urlField.isEnabled = false
        }
        
        if (browserOptions?.toolbarTop)! {
            if browserOptions?.toolbarTopBackgroundColor != "" {
                self.toolbarTop.backgroundColor = color(fromHexString: (browserOptions?.toolbarTopBackgroundColor)!)
            }
        }
        else {
            self.toolbarTop.isHidden = true
            self.toolbarTop_BottomToWebViewTopConstraint.isActive = false
            self.webView_TopFullScreenConstraint.isActive = true
        }
        
        if (browserOptions?.toolbarBottom)! {
            if browserOptions?.toolbarBottomBackgroundColor != "" {
                self.toolbarBottom.backgroundColor = color(fromHexString: (browserOptions?.toolbarBottomBackgroundColor)!)
            }
            self.toolbarBottom.isTranslucent = (browserOptions?.toolbarBottomTranslucent)!
        }
        else {
            self.toolbarBottom.isHidden = true
            self.toolbarBottom_TopToWebViewBottomConstraint.isActive = false
            self.webView_BottomFullScreenConstraint.isActive = true
        }
        
        if browserOptions?.closeButtonCaption != "" {
            closeButton.setTitle(browserOptions?.closeButtonCaption, for: .normal)
        }
        if browserOptions?.closeButtonColor != "" {
            closeButton.tintColor = color(fromHexString: (browserOptions?.closeButtonColor)!)
        }
        
        self.modalPresentationStyle = UIModalPresentationStyle(rawValue: (browserOptions?.presentationStyle)!)!
        self.modalTransitionStyle = UIModalTransitionStyle(rawValue: (browserOptions?.transitionStyle)!)!
    }
    
    func loadUrl(url: URL, headers: [String: String]?) {
        webView.loadUrl(url: url, headers: headers)
        updateUrlTextField(url: (webView.currentURL?.absoluteString)!)
    }
    
    // Load user requested url
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField.text != nil && textField.text != "" {
            let url = textField.text?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            let request = URLRequest(url: URL(string: url!)!)
            webView.load(request)
        }
        else {
            updateUrlTextField(url: (webView.currentURL?.absoluteString)!)
        }
        return false
    }
    
    func setWebViewFrame(_ frame: CGRect) {
        print("Setting the WebView's frame to \(NSStringFromCGRect(frame))")
        webView.frame = frame
    }
    
    @objc func reload () {
        webView.reload()
    }
    
    @objc func share () {
        let vc = UIActivityViewController(activityItems: [webView.currentURL ?? ""], applicationActivities: [])
        present(vc, animated: true, completion: nil)
    }
    
    @objc func close() {
        //currentURL = nil
        
        weak var weakSelf = self
        
        // Run later to avoid the "took a long time" log message.
        DispatchQueue.main.async(execute: {() -> Void in
            if (weakSelf?.responds(to: #selector(getter: self.presentingViewController)))! {
                weakSelf?.presentingViewController?.dismiss(animated: true, completion: {() -> Void in
                    self.tmpWindow?.windowLevel = 0.0
                    UIApplication.shared.delegate?.window??.makeKeyAndVisible()
                    if (self.navigationDelegate != nil) {
                        self.navigationDelegate?.browserExit(uuid: self.uuid)
                    }
                })
            }
            else {
                weakSelf?.parent?.dismiss(animated: true, completion: {() -> Void in
                    self.tmpWindow?.windowLevel = 0.0
                    UIApplication.shared.delegate?.window??.makeKeyAndVisible()
                    if (self.navigationDelegate != nil) {
                        self.navigationDelegate?.browserExit(uuid: self.uuid)
                    }
                })
            }
        })
    }
    
    @objc func goBack() {
        if canGoBack() {
            webView.goBack()
            updateUrlTextField(url: (webView?.url?.absoluteString)!)
        }
    }
    
    func canGoBack() -> Bool {
        return webView.canGoBack
    }
    
    @objc func goForward() {
        if canGoForward() {
            webView.goForward()
            updateUrlTextField(url: (webView?.url?.absoluteString)!)
        }
    }
    
    func canGoForward() -> Bool {
        return webView.canGoForward
    }
    
    @objc func goBackOrForward(steps: Int) {
        webView.goBackOrForward(steps: steps)
        updateUrlTextField(url: (webView?.url?.absoluteString)!)
    }
    
    func canGoBackOrForward(steps: Int) -> Bool {
        return webView.canGoBackOrForward(steps: steps)
    }
    
    func updateUrlTextField(url: String) {
        urlField.text = url
    }
    
    //
    // On iOS 7 the status bar is part of the view's dimensions, therefore it's height has to be taken into account.
    // The height of it could be hardcoded as 20 pixels, but that would assume that the upcoming releases of iOS won't
    // change that value.
    //
    
    func getStatusBarOffset() -> Float {
        let statusBarFrame: CGRect = UIApplication.shared.statusBarFrame
        let statusBarOffset: Float = Float(min(statusBarFrame.size.width, statusBarFrame.size.height))
        return statusBarOffset
    }
    
    // Helper function to convert hex color string to UIColor
    // Assumes input like "#00FF00" (#RRGGBB).
    // Taken from https://stackoverflow.com/questions/1560081/how-can-i-create-a-uicolor-from-a-hex-string
    
    func color(fromHexString: String, alpha:CGFloat? = 1.0) -> UIColor {
        
        // Convert hex string to an integer
        let hexint = Int(self.intFromHexString(hexStr: fromHexString))
        let red = CGFloat((hexint & 0xff0000) >> 16) / 255.0
        let green = CGFloat((hexint & 0xff00) >> 8) / 255.0
        let blue = CGFloat((hexint & 0xff) >> 0) / 255.0
        let alpha = alpha!
        
        // Create color object, specifying alpha as well
        let color = UIColor(red: red, green: green, blue: blue, alpha: alpha)
        return color
    }
    
    func intFromHexString(hexStr: String) -> UInt32 {
        var hexInt: UInt32 = 0
        // Create scanner
        let scanner: Scanner = Scanner(string: hexStr)
        // Tell scanner to skip the # character
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "#")
        // Scan hex value
        scanner.scanHexInt32(&hexInt)
        return hexInt
    }

    func setOptions(newOptions: InAppBrowserOptions, newOptionsMap: [String: Any]) {
        
        let newInAppWebViewOptions = InAppWebViewOptions()
        newInAppWebViewOptions.parse(options: newOptionsMap)
        self.webView.setOptions(newOptions: newInAppWebViewOptions, newOptionsMap: newOptionsMap)
        
        if newOptionsMap["hidden"] != nil && browserOptions?.hidden != newOptions.hidden {
            if newOptions.hidden {
                self.navigationDelegate?.hide(uuid: self.uuid)
            }
            else {
                self.navigationDelegate?.show(uuid: self.uuid)
            }
        }

        if newOptionsMap["hideUrlBar"] != nil && browserOptions?.hideUrlBar != newOptions.hideUrlBar {
            self.urlField.isHidden = newOptions.hideUrlBar
            self.urlField.isEnabled = !newOptions.hideUrlBar
        }
        
        if newOptionsMap["toolbarTop"] != nil && browserOptions?.toolbarTop != newOptions.toolbarTop {
            self.webView_TopFullScreenConstraint.isActive = !newOptions.toolbarTop
            self.toolbarTop.isHidden = !newOptions.toolbarTop
            self.toolbarTop_BottomToWebViewTopConstraint.isActive = newOptions.toolbarTop
        }
        
        if newOptionsMap["toolbarTopBackgroundColor"] != nil && browserOptions?.toolbarTopBackgroundColor != newOptions.toolbarTopBackgroundColor && newOptions.toolbarTopBackgroundColor != "" {
            self.toolbarTop.backgroundColor = color(fromHexString: newOptions.toolbarTopBackgroundColor)
        }
        
        if newOptionsMap["toolbarBottom"] != nil && browserOptions?.toolbarBottom != newOptions.toolbarBottom {
            self.webView_BottomFullScreenConstraint.isActive = !newOptions.toolbarBottom
            self.toolbarBottom.isHidden = !newOptions.toolbarBottom
            self.toolbarBottom_TopToWebViewBottomConstraint.isActive = newOptions.toolbarBottom
        }
        
        if newOptionsMap["toolbarBottomBackgroundColor"] != nil && browserOptions?.toolbarBottomBackgroundColor != newOptions.toolbarBottomBackgroundColor && newOptions.toolbarBottomBackgroundColor != "" {
            self.toolbarBottom.backgroundColor = color(fromHexString: newOptions.toolbarBottomBackgroundColor)
        }
        
        if newOptionsMap["toolbarBottomTranslucent"] != nil && browserOptions?.toolbarBottomTranslucent != newOptions.toolbarBottomTranslucent {
            self.toolbarBottom.isTranslucent = newOptions.toolbarBottomTranslucent
        }
        
        if newOptionsMap["closeButtonCaption"] != nil && browserOptions?.closeButtonCaption != newOptions.closeButtonCaption && newOptions.closeButtonCaption != "" {
            closeButton.setTitle(newOptions.closeButtonCaption, for: .normal)
        }
        
        if newOptionsMap["closeButtonColor"] != nil && browserOptions?.closeButtonColor != newOptions.closeButtonColor && newOptions.closeButtonColor != "" {
            closeButton.tintColor = color(fromHexString: newOptions.closeButtonColor)
        }
        
        if newOptionsMap["presentationStyle"] != nil && browserOptions?.presentationStyle != newOptions.presentationStyle {
            self.modalPresentationStyle = UIModalPresentationStyle(rawValue: newOptions.presentationStyle)!
        }
        
        if newOptionsMap["transitionStyle"] != nil && browserOptions?.transitionStyle != newOptions.transitionStyle {
            self.modalTransitionStyle = UIModalTransitionStyle(rawValue: newOptions.transitionStyle)!
        }
        
        self.browserOptions = newOptions
        self.webViewOptions = newInAppWebViewOptions
    }
    
    func getOptions() -> [String: Any]? {
        if (self.browserOptions == nil || self.webView.getOptions() == nil) {
            return nil
        }
        var optionsMap = self.browserOptions!.getHashMap()
        optionsMap.merge(self.webView.getOptions()!, uniquingKeysWith: { (current, _) in current })
        return optionsMap
    }

}
