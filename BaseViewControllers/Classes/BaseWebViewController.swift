//
//  BaseWebViewController.swift
//  BaseViewControllers
//
//  Created by acalism on 16-9-29.
//  Copyright © 2016 acalism. All rights reserved.
//

import UIKit
import WebKit


class BaseWebViewController: BaseScrollViewController /* , WKScriptMessageHandler */ {

    fileprivate let goBackButton = UIBarButtonItem(image: UIImage(named: "backbutton"), style: .plain, target: nil, action: #selector(goBackButtonPressed(sender:)))
    fileprivate let goForwardButton = UIBarButtonItem(image: UIImage(named: "forwardbutton"), style: .plain, target: nil, action: #selector(goForwardButtonPressed(sender:)))
    fileprivate let stopButton = UIBarButtonItem(barButtonSystemItem: .stop, target: nil, action: #selector(stopButtonPressed(sender:)))
    fileprivate let refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: nil, action: #selector(refreshButtonPressed(sender:)))
    fileprivate let actionButton = UIBarButtonItem(barButtonSystemItem: .action, target: nil, action: #selector(actionButtonPressed(sender:)))
    fileprivate let openInSafariButton = UIBarButtonItem(image: UIImage(named: "safari-navBar")!.withRenderingMode(.alwaysTemplate), style: .plain, target: nil, action: #selector(openInSafari(sender:)))
    fileprivate let fixedSeparator = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
    fileprivate let flexibleSeparator = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

    fileprivate var actionButtonHidden = true {
        didSet {
            updateToolBar()
        }
    }

    fileprivate var myWebVCContext = 3
    fileprivate var networkActivityCount = 0

    var useDocumentTitle = true
    fileprivate var originalNavigationBarShadowImage: UIImage? = nil

    let webView: WKWebView

    let progressView = UIProgressView(progressViewStyle: .default)

    let originalURL: URL

    var url: URL?
    fileprivate var urlRequest: URLRequest?


    deinit {
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), context: &myWebVCContext)

        // 删除注入的js
        webView.configuration.userContentController.removeAllUserScripts()
        webView.stopLoading() // 停止加载
        Common.networkActivityCount -= networkActivityCount  // 修正
    }

    init(url: Foundation.URL, configuration: WKWebViewConfiguration? = nil) {
        originalURL = url // URL(string: "https://www.zhihu.com/question/51997376/answer/129065505?from=groupmessage&isappinstalled=0")
        if let config = configuration {
            webView = WKWebView(frame: .zero, configuration: config)
        } else {
            webView = WKWebView(frame: .zero)
        }
        self.url = url
        let policy = URLRequest.CachePolicy.useProtocolCachePolicy
        urlRequest = URLRequest(url: url, cachePolicy: policy, timeoutInterval: Common.networkTimeout * 2) // webView给更多超时时间
        urlRequest = URLRequest(url: url)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override func loadView() {

        useDefaultScrollView = false

        super.loadView()

        scrollView = webView.scrollView

        view.addSubview(webView)
        webView.frame = view.bounds
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        webView.uiDelegate = self
        webView.navigationDelegate = self

        webView.allowsBackForwardNavigationGestures = true
        if #available(iOS 9.0, *) {
            webView.allowsLinkPreview = true
        } else {
            // Fallback on earlier versions
        }

        view.addSubview(progressView)
        progressView.trackTintColor = .clear
        progressView.progressTintColor = .green

        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: [.old, .new], context: &myWebVCContext)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        edgesForExtendedLayout = UIRectEdge.bottom // 因为toolBar是透明的

        goBackButton.target = self
        goForwardButton.target = self
        stopButton.target = self
        refreshButton.target = self
        actionButton.target = self
        openInSafariButton.target = self
        fixedSeparator.width = 50

        if let request = urlRequest {
            webView.load(request)
            print("url error：\(String(unwrap: url))")
        }

        guard let nav = navigationController else {
            return
        }
        originalNavigationBarShadowImage = nav.navigationBar.shadowImage
        nav.navigationBar.shadowImage = UIImage()
        updateToolBar(animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 真的有用吗？
        if nil == webView.title {
            webView.reload() // 白屏问题
        }
    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        progressView.frame = CGRect(x: 0, y: topLayoutGuide.length, width: view.bounds.width, height: 1)
        scrollView.contentInset = UIEdgeInsets(top: topLayoutGuide.length, left: 0, bottom: bottomLayoutGuide.length, right: 0) // tabBar高度为49
        //print("scrollView.contentInset is: \(scrollView.contentInset)")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let nav = navigationController {
            nav.navigationBar.shadowImage = originalNavigationBarShadowImage
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        webView.stopLoading()
    }


    // MARK: - Rotation
    override var shouldAutorotate: Bool {
        return true
    }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }

    // MARK: - Status Bar
    override var prefersStatusBarHidden: Bool {
        return false
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
    override var childViewControllerForStatusBarStyle: UIViewController? {
        return nil
    }
    override var childViewControllerForStatusBarHidden: UIViewController? {
        return nil
    }
    
// MARK: - Error Tip

    override func clearContent(animated: Bool) {
        super.clearContent(animated: animated)
        webView.isHidden = true
    }
    override func loadContent(animated: Bool) {
        super.loadContent(animated: animated)

        networkWarningView.isHidden = true

        webView.isHidden = false
        guard let urlRequest = urlRequest else { return }
        webView.load(urlRequest)
    }

    override func retryLoad() {
        networkWarningView.warningType = .loading
        loadContent(animated: false)
    }
}


extension BaseWebViewController {
    func updateToolBar(animated: Bool = true) {
        let canGoBack = webView.canGoBack
        let canGoForward = webView.canGoForward
        goBackButton.isEnabled = canGoBack
        goForwardButton.isEnabled = canGoForward
        var items = [goBackButton, flexibleSeparator, goForwardButton, flexibleSeparator, refreshButton, flexibleSeparator, openInSafariButton]
        if webView.isLoading {
            items[4] = stopButton
        }
        if !actionButtonHidden {
            items.append(actionButton)
        }
        setToolbarItems(items, animated: animated)
    }

    func refreshButtonPressed(sender: UIBarButtonItem) {
        webView.stopLoading()
        webView.reload()
    }
    func stopButtonPressed(sender: UIBarButtonItem) {
        webView.stopLoading()
    }
    func goBackButtonPressed(sender: UIBarButtonItem) {
        webView.goBack()
        updateToolBar()
    }
    func goForwardButtonPressed(sender: UIBarButtonItem) {
        webView.goForward()
        updateToolBar()
    }
    func actionButtonPressed(sender: UIBarButtonItem) {
        //
    }
    func openInSafari(sender: UIBarButtonItem) {
        if let u = webView.url {
            UIApplication.shared.openURL(u)
        }
    }
}

/// 经验值
private let minProgress: Float = 0.06

// MARK: - Progress
extension BaseWebViewController {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &myWebVCContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        guard keyPath == #keyPath(WKWebView.estimatedProgress) else { return }
        if let p = change?[.newKey] as? Double {
            //print("progress: \(p)")
            if p < 1 {
                progressView.isHidden = false
                progressView.setProgress(max(minProgress, Float(p)), animated: true) // 最小不应为0，否则不可见
            } else { // didFail在前，progress = 1 在后发生。
                progressView.setProgress(0, animated: false) // 恢复进度为0，否则下次重新开始时，动画是倒走的。
                progressView.isHidden = true
            }
        } else {
            print("no new progress value")
        }
    }

    func onStartRequest() {
        Common.networkActivityCount += 1
        networkActivityCount += 1

        networkWarningView.warningType = .noError // 重新开始，先清除错误

//        progressView.isHidden = false
//        progressView.setProgress(minProgress, animated: true) // 最小不应为0，否则用户感知不到
    }

    func finalizeRequest() {
        Common.networkActivityCount -= 1
        networkActivityCount -= 1
    }
}


// MARK: - WKUIDelegate
extension BaseWebViewController: WKUIDelegate {
    //@available(iOS 8.0, *)
    func webView(_ wv: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        print(#function, "configuration = \(configuration), navigationAction = \(navigationAction), windowFeatures = \(windowFeatures)")
        if navigationAction.targetFrame == nil || !navigationAction.targetFrame!.isMainFrame {
            wv.load(navigationAction.request) // 否则<a target="_blank" href="http://www.qq.com/contract.shtml">《腾讯服务协议》</a> 就打不开了
        }
        return nil
    }

    //@available(iOS 9.0, *)
    func webViewDidClose(_ wv: WKWebView) {
        print(#function)
    }


    //@available(iOS 8.0, *)
    func webView(_ wv: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Swift.Void) {
        print(#function, "message = \(message), frame = \(frame)")
//        if !appeared { /* UIViewController of WKWebView has finish push or present animation */
//            completionHandler()
//            return
//        }
        let ac = UIAlertController(title: frame.request.url?.host, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "确认", style: .default, handler: { (aa) in
            completionHandler()
        }))
        present(ac, animated: true, completion: nil)
//        if appeared { /* UIViewController of WKWebView is visible */
//            present(ac, animated: true, completion: nil)
//        } else {
//            completionHandler()
//        }
    }


    //@available(iOS 8.0, *)
    func webView(_ wv: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Swift.Void) {
        print(#function, "message = \(message), frame = \(frame)")
//        if !appeared { /* UIViewController of WKWebView has finish push or present animation */
//            completionHandler(false)
//            return
//        }
        let ac = UIAlertController(title: frame.request.url?.host, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "确认", style: .default, handler: { (aa) in
            completionHandler(true)
        }))
        ac.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { (aa) in
            completionHandler(false)
        }))
        present(ac, animated: true, completion: nil)
//        if appeared { /* UIViewController of WKWebView is visible */
//            present(ac, animated: true, completion: nil)
//        } else {
//            completionHandler(false)
//        }
    }


    //@available(iOS 8.0, *)
    func webView(_ wv: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Swift.Void) {
        print(#function, "prompt = \(prompt), defaultText = \(defaultText ?? ""), frame = \(frame)")
        var textField: UITextField? = nil
        let ac = UIAlertController(title: frame.request.url?.host, message: prompt, preferredStyle: .alert)
        ac.addTextField { (tf) in
            //tf.placeholder = defaultText
            tf.text = defaultText
            textField = tf
        }
        ac.addAction(UIAlertAction(title: "确认", style: .default, handler: { (aa) in
            completionHandler(textField?.text)
        }))
        ac.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { (aa) in
            completionHandler(nil)
        }))
        present(ac, animated: true, completion: nil)
    }


    @available(iOS 10.0, *)
    func webView(_ wv: WKWebView, shouldPreviewElement elementInfo: WKPreviewElementInfo) -> Bool {
        print(#function, "elementInfo = \(elementInfo)")
        return true
    }


    @available(iOS 10.0, *)
    func webView(_ wv: WKWebView, previewingViewControllerForElement elementInfo: WKPreviewElementInfo, defaultActions previewActions: [WKPreviewActionItem]) -> UIViewController? {
        print(#function, "elementInfo = \(elementInfo), previewActions = \(previewActions)")
        return nil
    }


    //@available(iOS 10.0, *)
    func webView(_ wv: WKWebView, commitPreviewingViewController previewingViewController: UIViewController) {
        print(#function, "previewingViewController = \(previewingViewController)")
    }
}


// MARK: - WKNavigationDelegate
extension BaseWebViewController: WKNavigationDelegate {
    func webView(_ wv: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {
        print(#function, "navigationAction = \(navigationAction)")
        switch navigationAction.navigationType {
        case .linkActivated: break // 0
        case .formSubmitted: break // 1
        case .backForward: break // 2
        case .reload: break // 3
        case .formResubmitted: break // 4
        case .other: break // 开始时是other，即-1，其他几个都是用户行为
        }
        /*
         Error Domain=WebKitErrorDomain Code=102 "Frame load interrupted" UserInfo={_WKRecoveryAttempterErrorKey=<WKReloadFrameErrorRecoveryAttempter: 0x170437b20>, NSErrorFailingURLStringKey=itms-appss://itunes.apple.com/cn/app/yu-piao-er-dian-ying-yan-chu/id481589275?mt=8, NSErrorFailingURLKey=itms-appss://itunes.apple.com/cn/app/yu-piao-er-dian-ying-yan-chu/id481589275?mt=8, NSLocalizedDescription=帧框加载已中断}
         */
        guard let url = navigationAction.request.url, let uc = URLComponents(url: url, resolvingAgainstBaseURL: true), let scheme = uc.scheme else {
            print(#function, "这个request不正常\(navigationAction.request)")
            decisionHandler(.cancel)
            return
        }
        if url.absoluteString == "about:blank" { // “软件许可及服务协议”跳转到“微信公众平台服务协议”后再跳转时，会出现target="_blank"
            decisionHandler(.cancel)
            return
        }
        let isNormalURL = (scheme == "http" || scheme == "https")
        if !isNormalURL/* && UIApplication.shared.canOpenURL(url) */ {
            decisionHandler(.cancel)

            let completed = UIApplication.shared.openURL(url)
            print(#function, "\(completed ? "successfully" : "failed to") open another app with url: \(url)")
        } else if url.host == "itunes.apple.com" { // 跳转app store 安装app，或跳转其他注册了相应scheme的第三方app
            decisionHandler(.cancel)

            let ac = UIAlertController(title: nil, message: "将会离开\"\(Common.displayName)\"\n并跳转到App Store", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "取消", style: .cancel))
            ac.addAction(UIAlertAction(title: "确定", style: .default, handler: { (aa) in
                UIApplication.shared.openURL(url)
                print(#function, "open App Store with url: \(url)")
            }))
            present(ac, animated: true, completion: nil)
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(_ wv: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        let nav = navigation == nil ? "nil" : "\(navigation!)"
        print(#function, "navigation = \(nav)")
        updateToolBar()
        onStartRequest()
    }

    func webView(_ wv: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Swift.Void) {
        print(#function, "navigationResponse = \(navigationResponse)")
        decisionHandler(.allow)
    }

    func webView(_ wv: WKWebView, didCommit navigation: WKNavigation!) {
        let nav = navigation == nil ? "nil" : "\(navigation!)"
        print(#function, "navigation = \(nav)")
    }

    func webView(_ wv: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        let nav = navigation == nil ? "nil" : "\(navigation!)"
        print(#function, "navigation = \(nav)")
    }

    func webView(_ wv: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let nav = navigation == nil ? "nil" : "\(navigation!)"
        print(#function, "navigation = \(nav), error = \(error)")
        updateToolBar()
        self.webView(wv, error: error)
    }

    func webView(_ wv: WKWebView, didFinish navigation: WKNavigation!) {
        let nav = navigation == nil ? "nil" : "\(navigation!)"
        print(#function, "navigation = \(nav)")
        if useDocumentTitle {
            title = wv.title
        }
        updateToolBar()
        finalizeRequest()
        networkWarningView.warningType = .noError
        url = wv.url
    }

    func webView(_ wv: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let nav = navigation == nil ? "nil" : "\(navigation!)"
        print(#function, "navigation = \(nav), error = \(error)")
        updateToolBar()
        //self.webView(wv, error: error)
        finalizeRequest()
    }

    // @available(iOS 9.0, *)
    func webViewWebContentProcessDidTerminate(_ wv: WKWebView) {
        print(#function)
        wv.reload() // WKWebView总体内存占用过大，页面即将白屏的时候，reload以解决白屏问题，此时webView.url尚不为nil
    }


//    func webView(_ wv: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) {
//        print(#function, "challenge = \(challenge)")
//        // https自有证书不通过时
//        guard challenge.previousFailureCount < 5 else {
//            completionHandler(URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge, nil)  // 跳不过，就放弃
//            return
//        }
//        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
//    }
}

// MARK: - custom
extension BaseWebViewController {
    func webView(_ wv: WKWebView, error: Error) {
        var retryMessage = "加载失败，请重试"
        let err = error as NSError
        if err.domain == NSURLErrorDomain {
            switch err.code {
            case NSURLErrorUnknown: fallthrough
            case NSURLErrorCancelled: fallthrough // "当网页内部链接跳转时"
            case NSURLErrorBadURL: break
            case NSURLErrorTimedOut: // TIMED OUT:
                retryMessage = "连接超时，请重试"
            case NSURLErrorUnsupportedURL:
                retryMessage = "非法链接"
            case NSURLErrorCannotFindHost: // SERVER CANNOT BE FOUND
                retryMessage = "找不到服务器"
            case NSURLErrorCannotConnectToHost:
                retryMessage = "无法连接到服务器"
            case NSURLErrorNetworkConnectionLost:
                retryMessage = "网络连接丢失"
            case NSURLErrorDNSLookupFailed: fallthrough
            case NSURLErrorHTTPTooManyRedirects: fallthrough
            case NSURLErrorResourceUnavailable: fallthrough
            case NSURLErrorNotConnectedToInternet:
                retryMessage = "无网络连接"
            case NSURLErrorRedirectToNonExistentLocation: fallthrough
            case NSURLErrorBadServerResponse: fallthrough
            case NSURLErrorUserCancelledAuthentication: fallthrough
            case NSURLErrorUserAuthenticationRequired: fallthrough
            case NSURLErrorZeroByteResource: fallthrough
            case NSURLErrorCannotDecodeRawData: fallthrough
            case NSURLErrorCannotDecodeContentData: fallthrough
            case NSURLErrorCannotParseResponse: break
            case -1022: //NSURLErrorAppTransportSecurityRequiresSecureConnection: fallthrough // -1022
                retryMessage = "加载了不安全的链接"
            case NSURLErrorFileDoesNotExist: // URL NOT FOUND ON SERVER
                retryMessage = "目标不存在"
            case NSURLErrorFileIsDirectory: fallthrough
            case NSURLErrorNoPermissionsToReadFile: fallthrough
            case NSURLErrorDataLengthExceedsMaximum: break

            //SSLerrors
            case NSURLErrorSecureConnectionFailed: fallthrough
            case NSURLErrorServerCertificateHasBadDate: fallthrough
            case NSURLErrorServerCertificateUntrusted: fallthrough
            case NSURLErrorServerCertificateHasUnknownRoot: fallthrough
            case NSURLErrorServerCertificateNotYetValid: fallthrough
            case NSURLErrorClientCertificateRejected: fallthrough
            case NSURLErrorClientCertificateRequired: fallthrough
            case NSURLErrorCannotLoadFromNetwork: break

            //DownloadandfileI/Oerrors
            case NSURLErrorCannotCreateFile: fallthrough
            case NSURLErrorCannotOpenFile: fallthrough
            case NSURLErrorCannotCloseFile: fallthrough
            case NSURLErrorCannotWriteToFile: fallthrough
            case NSURLErrorCannotRemoveFile: fallthrough
            case NSURLErrorCannotMoveFile: fallthrough
            case NSURLErrorDownloadDecodingFailedMidStream: fallthrough
            case NSURLErrorDownloadDecodingFailedToComplete: break

            case NSURLErrorInternationalRoamingOff:
                retryMessage = "您关闭了数据漫游，请打开数据漫游后重试"
            case NSURLErrorCallIsActive: fallthrough
            case NSURLErrorDataNotAllowed: fallthrough
            case NSURLErrorRequestBodyStreamExhausted: break

            case NSURLErrorBackgroundSessionRequiresSharedContainer: fallthrough
            case NSURLErrorBackgroundSessionInUseByAnotherProcess: fallthrough
            case NSURLErrorBackgroundSessionWasDisconnected: break

            default:
                break
            }
            print("<h1>" + retryMessage + "</h1>" + err.description)
//            wv.loadHTMLString(retryMessage, baseURL: nil)

            if !webView.isLoading {  // 此判断条件无用，fail时已经stop了，但还会再start
                networkWarningView.warningType = .loadFailed
            }

            finalizeRequest()
        } else if err.domain == WKErrorDomain { // "WebKitErrorDomain"  // 实为UIWebVeiw的错误信息
            let wkError = WKError(_nsError: err)
            // err.code == 102 // "包含 app store 链接"
            // err.code == 204 // "当链接就视频路径时（不影响视频正常播放）"
            switch wkError.code {
            case .unknown:
                break
            case .webContentProcessTerminated:
                break
            case .webViewInvalidated:
                break
            case .javaScriptExceptionOccurred:
                break
            case .javaScriptResultTypeIsUnsupported:
                break
            }
        }
    }
}
