//
//  BaseViewController.swift
//  BaseViewControllers
//
//  Created by acalism on 16-8-4.
//  Copyright © 2016年 acalism. All rights reserved.
//

import UIKit


let commonHorizontalMargin: CGFloat = 14

protocol ContentLoadingProtocol {
    func reloadContent(animated: Bool)
    func loadContent(animated: Bool)
    func clearContent(animated: Bool)
}

protocol PullActionForScrollView {
    func topPull(sender: UIControl?)
    func bottomPull(sender: UIControl?)
}



fileprivate let logLifeCycle = false
fileprivate let logTag = "BaseViewController"



protocol AutoRefreshable {
    var firstLoad: Bool { get set }
    var shouldAutoRefresh: Bool { get set }
    var autoRefreshInterval: TimeInterval { get set }
    var refreshDate: Date? { get set }
}



/// 如何使用NetworkWarningView？
/// 1. 提供 NetworkWarningView 的 superview，即初始化 errorContentView，若不设置则 NetworkWarningView 会加到 self.view （默认居中置于superview中）
/// 2. 确保已提供重加载请求入口 topPull(_:) 方法
/// 3. 在网络请求的 fail 处理分支设置networkWarningView.warningType = .loadFailed，在其 success 处理分支设置 networkWarningView.warningType = .noError
/// 4. 处理 clearContent(_:) 和 loadContent(_:)，分别对应 .loadFailed 和 .noError 逻辑 ———— 对于 UITableView 和 UICollectionView，通常只需要将其数据源置空和填入数据并 reloadData() 就行 （此部分跟具体业务关系挺大，有些业务在出错时只需要隐藏部分内容，有些则需要全隐藏，有些还要处理子模块的数据加载）


/// 自定义的ViewController体系的基类
class BaseViewController: UIViewController, NetworkWarningViewDelegate, ContentLoadingProtocol, PullActionForScrollView, ImageMoveTransitionBackFrom {

    deinit {
        NotificationCenter.default.removeObserver(self)
    }


    /// networkWarningView 容器，为空则直接放在view里，并居中放置
    var errorContentView: UIView? = nil
    let networkWarningView = NetworkWarningView(frame: CGRect.zero)

    var hidesToolBarWhenPushed = true // 默认不使用ToolBar

    private(set) var appeared = false


    // MARK: - AutoRefreshable

    var firstLoad = true
    var shouldAutoRefresh = false
    var autoRefreshInterval = 3600.0
    var refreshDate : Date? // 需在请求成功时设置其值为 Date()

    // MARK: - ViewController Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white

        // Do any additional setup after loading the view.

        // 上下是否要被 navigationBar 和 tooBar 覆盖的问题，都在下面这两个属性——————它们是协作关系
        automaticallyAdjustsScrollViewInsets = false
        edgesForExtendedLayout = UIRectEdge()

        hideBackBarButtonTitle()


        // a. 添加 networkWarningView
        (errorContentView ?? view).addSubview(networkWarningView)
        networkWarningView.actionButton.addTarget(self, action: #selector(retryLoad), for: .touchUpInside)
        networkWarningView.delegate = self

        // 不是 childViewController，且上一个 vc 遵守 ImageMoveTransitionFrom 协议
        if let vcs = navigationController?.viewControllers, vcs.contains(self), vcs.count >= 2, vcs[vcs.count - 2] is ImageMoveTransitionFrom {
            //useCustomPercentDrivenTransition = true
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // b. 从下一个页面返回时自动重加载（如果本页加载失败）
        if networkWarningView.warningType == .loadFailed {
            networkWarningView.actionButton.sendActions(for: .touchUpInside)
        } else if !firstLoad && (refreshDate == nil || (shouldAutoRefresh && (refreshDate!.timeIntervalSinceNow > autoRefreshInterval || refreshDate!.timeIntervalSinceNow < -autoRefreshInterval))) {
            //topPull(sender: nil) // 正在全屏播放，然后切回来，却自动下拉了一次。。蛋疼不
        }
        firstLoad = false

        if let nav = navigationController, nav.topViewController == self, nav.isToolbarHidden != hidesToolBarWhenPushed {
            nav.setToolbarHidden(hidesToolBarWhenPushed, animated: animated)
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        // c. 依需要调整 networkWarningView 在 superview 中的位置
        let sv = errorContentView ?? view!
        networkWarningView.sizeToFit()
        networkWarningView.center = CGPoint(x: sv.bounds.width / 2, y: sv.bounds.height / 2)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        appeared = true

        configureEdgePan()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let nav = navigationController {
            nav.setToolbarHidden(true, animated: animated)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        appeared = false
    }

    // MARK: - NetworkWarningViewDelegate


    /// d. 失败重加载……
    func retryLoad() {
        networkWarningView.warningType = .loading
        topPull(sender: nil)
    }

    /// e. 处理错误状态变更后的业务逻辑
    func errorChanged(oldValue: NetworkWarningView.WarningType, newValue: NetworkWarningView.WarningType) {
        if newValue != .noError {
            clearContent(animated: false)
        } else if newValue != oldValue {
            loadContent(animated: false)
        }
    }

    // MARK: - ContentLoadingProtocol

    func reloadContent(animated: Bool) {
        clearContent(animated: animated)
        loadContent(animated: animated)
    }

    /// 不假定可重复调用
    func loadContent(animated: Bool) {
        //
    }

    /// 假定可重复调用
    func clearContent(animated: Bool) {
        //
    }


    // MARK: - PullActionForScrollView

    func topPull(sender: UIControl?) {
        //
    }

    func bottomPull(sender: UIControl?) {
        //
    }




    // MARK: - ImageMoveTransitionBackFrom

    var percentDrivenTransition: UIPercentDrivenInteractiveTransition?
    var edgePanGestureRecognizer: UIScreenEdgePanGestureRecognizer?

    var useCustomPercentDrivenTransition = false

    func configureEdgePan() {
        guard useCustomPercentDrivenTransition else { return }
        guard nil == edgePanGestureRecognizer else { return }
        let pan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(onEdgePan(_:)))
        edgePanGestureRecognizer = pan
        pan.edges = .left
        view.addGestureRecognizer(pan)
    }

    func onEdgePan(_ sender: UIScreenEdgePanGestureRecognizer) {

        let progress = sender.translation(in: view).x / view.bounds.width

        switch sender.state {
        case .began:
            percentDrivenTransition = UIPercentDrivenInteractiveTransition()
            if let nav = navigationController as? BaseNavigationController { // IMPORTANT: 否则不生效
                nav.percentDrivenTransition = percentDrivenTransition
            } else {
                fatalError("ImageMoveTransitionFromBack's navigationController must be a kind of BaseNavigationController!!")
            }
            navigationController?.popViewController(animated: true)

        case .changed:
            percentDrivenTransition?.update(progress)

        case .cancelled, .ended, .failed:
            if progress > 0.2 {
                percentDrivenTransition?.finish()
            } else {
                percentDrivenTransition?.cancel()
            }
            percentDrivenTransition = nil

        default: // .possible
            break
        }
    }
}



extension BaseViewController {

    // MARK: - Rotation

    override var shouldAutorotate: Bool {
        return false
    }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }


    // MARK: - Status Bar

    override var childViewControllerForStatusBarStyle: UIViewController? {
        return nil
    }
    override var childViewControllerForStatusBarHidden: UIViewController? {
        return nil
    }
    override var prefersStatusBarHidden: Bool {
        return false
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
}



// MARK: - Navigation

extension UIViewController {
    /// 返回按钮不显示任何文字
    func hideBackBarButtonTitle() {
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }

    func dismissButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
}


//fileprivate let animationDuration: TimeInterval = 0.5
//
//extension UIViewController {
//    /// push风格的present
//    func pushingPresent(_ viewControllerToPresent: UIViewController, animated: Bool, completion: (() -> Void)?) {
//        guard animated else {
//            present(viewControllerToPresent, animated: animated, completion: completion)
//            return
//        }
//
//        let transition = CATransition()
//        transition.duration = animationDuration
//        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
//        transition.type = kCATransitionPush
//        transition.subtype = kCATransitionFromRight
//        view.window?.layer.add(transition, forKey: nil)
//        present(viewControllerToPresent, animated: false, completion: completion)
//    }
//
//    /// pop风格的dismiss
//    func poppingDismiss(animated: Bool, completion: (() -> Void)?) {
//        guard animated else {
//            dismiss(animated: animated, completion: completion)
//            return
//        }
//
//        let transition = CATransition()
//        transition.duration = animationDuration
//        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
//        transition.type = kCATransitionPush
//        transition.subtype = kCATransitionFromLeft
//        view.window?.layer.add(transition, forKey: nil)
//        dismiss(animated: false, completion: completion)
//    }
//}
