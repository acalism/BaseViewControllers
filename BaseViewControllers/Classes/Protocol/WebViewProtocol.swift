//
//  WebViewProtocol.swift
//  BaseViewControllers
//
//  Created by acalism on 17-4-20.
//  Copyright © 2017 acalism. All rights reserved.
//

import UIKit
import WebKit



protocol WebViewCommonProtocol {
    var title: String? { get }
    var url: URL? { get }
    var scrollView: UIScrollView { get }

    var canGoBack: Bool { get }
    var canGoForward: Bool { get }
    var isLoading: Bool { get }
    var isLoadingMainFrame: Bool { get }
    var estimatedProgress: Double { get }

//    func goBack() -> WKNavigation?
//    func goForward() -> WKNavigation?
//    func reload() -> WKNavigation?
    func common_goBack()
    func common_goForward()
    func common_reload()

    func load(url: URL)
    func load(request: URLRequest)

    func stopLoading()

    func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Swift.Void)?)

//    var allowsBackForwardNavigationGestures: Bool { get set }
}



fileprivate var keyForEstimatedProgress: Int = 0
fileprivate var keyForLoadingUIMainFrame: Int = 0
fileprivate var keyForLoadingWKMainFrame: Int = 0

extension UIWebView: WebViewCommonProtocol {
    func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?) {
        let str = stringByEvaluatingJavaScript(from: javaScriptString)
        completionHandler?(str, nil)
    }

    var url: URL? {
        return request?.url
    }

    var title: String? {
        return stringByEvaluatingJavaScript(from: "document.title")
    }

    func load(request: URLRequest) {
        loadRequest(request)
    }
    func load(url: URL) {
        let request = URLRequest(url: url)
        load(request: request)
    }

    func common_goBack() {
        goBack()
    }
    func common_goForward() {
        goForward()
    }
    func common_reload() {
        reload()
    }


    /// 需在委托方法中设置，才能get到有效值
    var isLoadingMainFrame: Bool {
        get {
            return objc_getAssociatedObject(self, &keyForLoadingUIMainFrame) as! Bool
        }
        set {
            objc_setAssociatedObject(self, &keyForLoadingUIMainFrame, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }

    /// 需在委托方法中设置，才能get到有效值
    var estimatedProgress: Double {
        get {
            return objc_getAssociatedObject(self, &keyForEstimatedProgress) as! Double
        }
        set {
            objc_setAssociatedObject(self, &keyForEstimatedProgress, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}

extension WKWebView: WebViewCommonProtocol {
    func load(request: URLRequest) {
        _ = load(request)
    }
    func load(url: URL) {
        let request = URLRequest(url: url)
        load(request: request)
    }

    func common_goBack() {
        goBack()
    }
    func common_goForward() {
        goForward()
    }
    func common_reload() {
        reload()
    }

    /// 需在委托方法中设置，才能get到有效值
    var isLoadingMainFrame: Bool {
        get {
            return objc_getAssociatedObject(self, &keyForLoadingWKMainFrame) as! Bool
        }
        set {
            objc_setAssociatedObject(self, &keyForLoadingWKMainFrame, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}



protocol WebViewHandleURLProtocol {
    /// WKNavigationType 与 UIWebViewNavigationType 一一对应。需注意的是：前者other为-1，而后者为5
    func handle(in hostViewController: UIViewController, webView: WebViewCommonProtocol, request: URLRequest, navigationType: WKNavigationType, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) -> Swift.Bool
}

extension WebViewHandleURLProtocol {
    @discardableResult
    func handle(in hostViewController: UIViewController, webView: WebViewCommonProtocol, request: URLRequest, navigationType: WKNavigationType, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) -> Swift.Bool {
        // 暂未对type作处理
        switch navigationType {
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
        guard let url = request.url, let uc = URLComponents(url: url, resolvingAgainstBaseURL: true), let scheme = uc.scheme else {
            print(#function, "【WKWebView】这个request不正常\(request)")
            decisionHandler(.cancel)
            return false
        }
        // 有些iframe 带 srcdoc 和 src 属性，这种跳转就是about:srcdoc吗？是的
        if url.absoluteString.hasPrefix("about:") { // “软件许可及服务协议”跳转到“微信公众平台服务协议”后再跳转时，会出现target="_blank"，
            decisionHandler(.allow)
            return true // 有些页面会一直尝试跳转about:blank，比如youku，
        }

        let isNormalURL = (scheme == "http" || scheme == "https")
        if !isNormalURL/* && UIApplication.shared.canOpenURL(url) */ {
            decisionHandler(.cancel)

            DispatchQueue.main.async {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [UIApplicationOpenURLOptionUniversalLinksOnly: false], completionHandler: { (completed) in
                        print("【WKWebView】\(completed ? "succeeded to" : "failed to") open another app with url: \(url)")
                    })
                } else {
                    UIApplication.shared.openURL(url)
                }
            }

            return false
        } else if url.host == "itunes.apple.com" { // 跳转app store 安装app，或跳转其他注册了相应scheme的第三方app
            decisionHandler(.cancel)

            DispatchQueue.main.async {
                let ac = UIAlertController(title: nil, message: "将会离开\"\(Common.displayName)\"\n并跳转到App Store", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "取消", style: .cancel))
                ac.addAction(UIAlertAction(title: "确定", style: .default, handler: { (aa) in
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(url, options: [UIApplicationOpenURLOptionUniversalLinksOnly: false], completionHandler: { (completed) in
                            print("【WKWebView】open App Store with url: \(url)")
                        })
                    } else {
                        UIApplication.shared.openURL(url)
                    }
                }))
                hostViewController.present(ac, animated: true, completion: nil)
            }

            return false
        } else {
            decisionHandler(.allow)
            return true
        }
    }
}

extension UIWebView: WebViewHandleURLProtocol {
    //
}
extension WKWebView: WebViewHandleURLProtocol {
    //
}


// 添加一些实用的方法

extension WKWebView {
    // sync version
    func evaluatingJavaScript(_ js: String) -> Any? {
        var res: Any? = nil
        var finish = false
        var count = 0
        evaluateJavaScript(js) { (result, error) in
            res = result
            finish = true
        }
        while !finish {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
            if count == 10 { // wait 1s
                finish = true
            }
            count += 1
        }
        return res
    }
}


extension WKWebViewConfiguration {
    func setup(autoPlaybackVideo: Bool = true) {
        guard autoPlaybackVideo else {
            return
        }
        allowsInlineMediaPlayback = !autoPlaybackVideo

        if #available(iOS 10.0, *) {
            mediaTypesRequiringUserActionForPlayback = autoPlaybackVideo ? [] : .all
        } else if #available(iOS 9.0, *) {
            requiresUserActionForMediaPlayback = !autoPlaybackVideo
        } else { // Fallback on earlier versions
            mediaPlaybackRequiresUserAction = !autoPlaybackVideo
        }
    }
}

extension UIWebView {
    func setup(autoPlaybackVideo: Bool = true) {
        guard autoPlaybackVideo else {
            return
        }
        allowsInlineMediaPlayback = !autoPlaybackVideo
        mediaPlaybackRequiresUserAction = !autoPlaybackVideo
    }
}
