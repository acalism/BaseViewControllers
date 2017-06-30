//
//  BaseNavigationController.swift
//  BaseViewControllers
//
//  Created by acalism on 17-3-1.
//  Copyright © 2017 acalism. All rights reserved.
//

import UIKit


class Common {

    static let titleAttributes: [String: Any] = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 15), NSForegroundColorAttributeName: UIColor.white]

    static let networkTimeout: TimeInterval = 10

    static let displayName = "此app"

    // MARK: - network
    static var networkActivityCount: Int = 0 {
        didSet {
            if networkActivityCount < 0 {
                networkActivityCount = 0
            } else {
                UIApplication.shared.isNetworkActivityIndicatorVisible = networkActivityCount > 0
            }
        }
    }
}


class BaseNavigationController: UINavigationController {

    /// A Boolean value indicating whether navigation controller is currently pushing a new view controller on the stack.
    fileprivate(set) var isDuringPushAnimation = false

    /// A real delegate of the class. `delegate` property is used only for keeping an internal state during
    /// animations – we need to know when the animation ended, and that info is available only
    /// from `navigationController:didShowViewController:animated:`.
    fileprivate(set) weak var realDelegate: UINavigationControllerDelegate? = nil


    deinit {
        delegate = nil
        interactivePopGestureRecognizer?.delegate = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if nil == delegate {
            delegate = self
        }

        commonConfigure()

        interactivePopGestureRecognizer?.delegate = self
    }

    override var delegate: UINavigationControllerDelegate? {
        get {
            return super.delegate
        }
        set {
            realDelegate = newValue === self ? nil : newValue
            super.delegate = newValue == nil ? nil : self
        }
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        isDuringPushAnimation = true
        if viewControllers.count > 0 {
            viewController.hidesBottomBarWhenPushed = true // 业务需要
        }
        super.pushViewController(viewController, animated: animated)
    }


    func commonConfigure() {
        navigationBar.barStyle = .black
        navigationBar.tintColor = .white
        navigationBar.titleTextAttributes = Common.titleAttributes

        // WebView 有 toolBar
        toolbar.barStyle = .black
        toolbar.tintColor = .white
    }


    weak var percentDrivenTransition: UIPercentDrivenInteractiveTransition?
}


// MARK: - UINavigationControllerDelegate

extension BaseNavigationController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        assert(interactivePopGestureRecognizer?.delegate === self, "AHKNavigationController won't work correctly if you change interactivePopGestureRecognizer's delegate.")

        isDuringPushAnimation = false

        realDelegate?.navigationController?(navigationController, didShow: viewController, animated: animated)
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        realDelegate?.navigationController?(navigationController, willShow: viewController, animated: animated)
    }

    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if let rd = realDelegate {
            return rd.navigationController?(navigationController, interactionControllerFor: animationController)
        }
        // print(navigationController.viewControllers.last!) // 已经被pop掉了
        return percentDrivenTransition
    }

    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let rd = realDelegate {
            return  rd.navigationController?(navigationController, animationControllerFor: operation, from: fromVC, to: toVC)
        }

        switch operation {
        case .none:
            break

        case .pop:
            if fromVC is ImageMoveTransitionFrom, toVC is ImageMoveTransitionTo {
                //return ImageMovePopTransition()
            }

        case .push:
            if fromVC is ImageMoveTransitionFrom, toVC is ImageMoveTransitionTo {
                return ImageMovePushTransition()
            }
        }
        return nil
    }

//    func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
//        //
//    }
//    func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
//        //
//    }
}


extension BaseNavigationController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.interactivePopGestureRecognizer {
            // Disable pop gesture in two situations:
            // 1) when the pop animation is in progress
            // 2) when user swipes quickly a couple of times and animations don't have time to be performed
            return viewControllers.count > 1 && !isDuringPushAnimation
        } else {
            return true // default value
        }
    }
}




// MARK: - 业务需求

// TODO: topViewController or visibleViewController ?
extension BaseNavigationController {
    // MARK: - Rotation
    override var shouldAutorotate: Bool {
        if let rvc = topViewController {
            return rvc.shouldAutorotate
        }
        return false
    }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let rvc = topViewController {
            return rvc.supportedInterfaceOrientations
        }
        return .portrait
    }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        if let rvc = topViewController {
            return rvc.preferredInterfaceOrientationForPresentation
        }
        return .portrait
    }


    // MARK: - Status Bar
    override var childViewControllerForStatusBarStyle: UIViewController? {
        return topViewController
    }
    override var childViewControllerForStatusBarHidden: UIViewController? {
        return topViewController
    }
    override var prefersStatusBarHidden: Bool {
        if let rvc = topViewController {
            return rvc.prefersStatusBarHidden
        }
        return false
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if let rvc = topViewController {
            return rvc.preferredStatusBarStyle
        }
        return .lightContent
    }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        if let rvc = topViewController {
            return rvc.preferredStatusBarUpdateAnimation
        }
        return .fade
    }
}




/*

// MARK: - Delegate Forwarder，来自NSObject的方法
/// Thanks for the idea goes to: https://github.com/steipete/PSPDFTextView/blob/ee9ce04ad04217efe0bc84d67f3895a34252d37c/PSPDFTextView/PSPDFTextView.m#L148-164
extension BaseNavigationController {

    override func responds(to aSelector: Selector!) -> Bool {
        let will = super .responds(to: aSelector)
        if let d = realDelegate, d.responds(to: aSelector) {
            return true
        }
        return will
    }

    // Swift无法实现下面两个方法，由于需转发的只是UINavigationConetrollerDelegate协议的方法，故不需借助下面两个方法
    // Unimplemented methods ———— Swift does not include `NSMethodSignature` and `NSInvocation`
//    - (NSMethodSignature *)methodSignatureForSelector:(SEL)s
//    {
//        return [super methodSignatureForSelector:s] ?: [(id)self.realDelegate methodSignatureForSelector:s];
//    }
//
//    - (void)forwardInvocation:(NSInvocation *)invocation
//    {
//        id delegate = self.realDelegate;
//        if ([delegate respondsToSelector:invocation.selector]) {
//            [invocation invokeWithTarget:delegate];
//        }
//    }
}
 */
