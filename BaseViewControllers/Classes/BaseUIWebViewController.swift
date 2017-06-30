//
//  BaseUIWebViewController.swift
//  BaseViewControllers
//
//  Created by acalism on 16-9-29.
//  Copyright © 2016 acalism. All rights reserved.
//

import UIKit

class BaseUIWebViewController: BaseScrollViewController, UIWebViewDelegate {

    var webView = UIWebView()

    var url: URL?

    init(URL: Foundation.URL?) {
        url = URL
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func loadView() {

        useDefaultScrollView = false

        super.loadView()

        scrollView = webView.scrollView

        view.addSubview(webView)
        webView.frame = view.bounds
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        guard let url = url else {
            return
        }
        let urlRequest = URLRequest(url: url)
        webView.loadRequest(urlRequest)
    }

    // MARK: - UIWebViewDelegate
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        return true
    }
    func webViewDidStartLoad(_ webView: UIWebView) {
        //
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
        //
    }

    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        //
    }

}
