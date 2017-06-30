//
//  BaseContainerView.swift
//  BaseViewControllers
//
//  Created by acalism on 16-12-2.
//  Copyright © 2016 acalism. All rights reserved.
//

import UIKit


protocol SizedViewControllerProtocol: class {

    /// 根据外层的size计算viewController.view的大小
    ///
    /// - Parameters:
    ///   - width: 外层的宽，0表示不限定
    ///   - height: 外层的高，0表示不限定
    /// - Returns: 与此相对应的view应有的size
    func viewSize(width: CGFloat, height: CGFloat) -> CGSize
}

//extension SizedViewControllerProtocol {
//
//    /// 计算view的size
//    ///
//    /// - Parameters:
//    ///   - width: 固定宽，0表示不限定
//    ///   - height: 固定高，0表示不限定
//    /// - Returns: 限制宽或高情况下的view应有的size
//    func viewSize(width: CGFloat = 0, height: CGFloat = 0) -> CGSize {
//        // iPhone 6 的尺寸是 375 * 667
//        let w = width == 0 ? 375 : width
//        let h = height == 0 ? 667 : height
//        return CGSize(width: w, height: h)
//    }
//}


/// 作为 UIViewController 的 container 使用
/// 初始化后，将本view添加到父view就行，废弃时removeFromSuperview即可
class BaseContainerView: UIView {

    fileprivate(set) weak var hostViewController: UIViewController? = nil

    let viewController: UIViewController

    init(viewController: UIViewController) {
        self.viewController = viewController
        super.init(frame: CGRect(origin: .zero, size: viewControllerSize))
        backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var viewControllerSize = CGSize(width: 320, height: 568) // 0是个过于特殊的大小，可能导致viewDidLoad里依赖于view大小的的初始化失败

    // TODO:
    override var intrinsicContentSize: CGSize {
        return viewControllerSize
    }

//    override func didMoveToSuperview() {
//        super.didMoveToSuperview()
//        //
//    }
//
//    override func willMove(toSuperview newSuperview: UIView?) {
//        super.willMove(toSuperview: newSuperview)
//        //
//    }


    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)

        guard nil == newWindow, nil != hostViewController else {
            return
        }
        hostViewController = nil
        viewController.willMove(toParentViewController: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParentViewController()
    }


    override func didMoveToWindow() {
        super.didMoveToWindow()

//        guard var vc: UIResponder = superview else {
//            return
//        }
//        while let res = vc.next, !(res is UIViewController) {
//            vc = res
//        }

        var res = next
        while res != nil {
            if let vc = res! as? UIViewController {
                hostViewController = vc
                break
            }
            res = res?.next
        }
        guard let hostVC = hostViewController else {
            return
        }
        hostVC.addChildViewController(viewController)
        addSubview(viewController.view)
        viewController.view.frame = bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewController.didMove(toParentViewController: hostVC)
    }

    // autoresizingMask不一定可靠
    override func layoutSubviews() {
        super.layoutSubviews()
        viewController.view.frame = bounds
    }
}
