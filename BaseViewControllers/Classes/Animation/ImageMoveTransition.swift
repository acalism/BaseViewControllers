//
//  ImageMoveTransition.swift
//  BaseViewControllers
//
//  Created by acalism on 17-4-17.
//  Copyright © 2017 acalism. All rights reserved.
//

import UIKit



/// push/pop 动画 从此 viewController 开始
protocol ImageMoveTransitionFrom: class {
    var transitionFromImage: UIImage? { get }
    var transitionFromView: UIView? { get }
    var transitionUsingSnapshotImage: Bool { get }
}



/// push/pop 动画 到此结束
protocol ImageMoveTransitionTo: class {
    var transitionToImageView: UIImageView? { get }
}

/// 左边缘返回手势
protocol ImageMoveTransitionBackFrom: NSObjectProtocol {
    var percentDrivenTransition: UIPercentDrivenInteractiveTransition? { get set }
    var edgePanGestureRecognizer: UIScreenEdgePanGestureRecognizer? { get set }

    var useCustomPercentDrivenTransition: Bool { get set }
    func configureEdgePan()
}



class ImageMovePushTransition: NSObject, UIViewControllerAnimatedTransitioning {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.45
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // 1.获取动画的源控制器和目标控制器。此时，toVC.viewWillAppear 已经被调用
        guard
            let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to),
            let from = fromVC as? ImageMoveTransitionFrom, let fv = from.transitionFromView,
            let to = toVC as? ImageMoveTransitionTo, let tiv = to.transitionToImageView
            else {
                transitionContext.completeTransition(true)
                return
        }

        // 2.创建一个 Cell 中 imageView 的截图，并把 imageView 隐藏，造成使用户以为移动的就是 imageView 的假象
        let snapshotView: UIView = {
            if from.transitionUsingSnapshotImage {
                return fv.snapshotView(afterScreenUpdates: false)!
            } else {
                let iv = UIImageView(image: from.transitionFromImage)
                iv.contentMode = fv.contentMode
                iv.clipsToBounds = true
                return iv
            }
        }()

        let container = transitionContext.containerView // UIViewControllerWrapperView
        snapshotView.frame = container.convert(fv.frame, from: fv.superview)
        fv.isHidden = true

        //3.设置目标控制器的位置，并把透明度设为0，在后面的动画中慢慢显示出来变为1
        toVC.view.frame = transitionContext.finalFrame(for: toVC)
        toVC.view.alpha = 0

        // 遮一下，满足设计童鞋的要求
//        let mask = UIView(frame: toVC.view.frame)
//        mask.backgroundColor = UIColor.white
//        toVC.view.addSubview(mask)

        //4.都添加到 container 中。注意顺序不能错了
        container.addSubview(toVC.view)
        container.addSubview(snapshotView)

        //5.执行动画
        /*
         这时avatarImageView.frame的值只是跟在IB中一样的，
         如果换成屏幕尺寸不同的模拟器运行时avatarImageView会先移动到IB中的frame,动画结束后才会突然变成正确的frame。
         所以需要在动画执行前执行一次toVC.avatarImageView.layoutIfNeeded() update一次frame
         */
        tiv.layoutIfNeeded()
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
            snapshotView.frame = container.convert(tiv.frame, from: tiv.superview)
            toVC.view.alpha = 1
        }, completion: { (finish: Bool) -> Void in
            fv.isHidden = false
            tiv.image = from.transitionFromImage // TODO: 需考虑使用snapshot的场景
            snapshotView.removeFromSuperview()
//            mask.removeFromSuperview()

            // 一定要记得动画完成后执行此方法，让系统管理 navigation
            transitionContext.completeTransition(true) // 触发调用 toVC.viewDidAppear 方法
        })
        // 要加在 super.viewDidAppear 后
//        if let backFrom = fromVC as? ImageMoveTransitionBackFrom {
//            backFrom.configureEdgePan()
//        }
    }
}




class ImageMovePopTransition: NSObject, UIViewControllerAnimatedTransitioning {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.45
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // fromVC.viewWillDisappear 已经调用
        guard
            let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to),
            let from = fromVC as? ImageMoveTransitionFrom, let fv = from.transitionFromView,
            let to = toVC as? ImageMoveTransitionTo, let tiv = to.transitionToImageView
            else {
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                return  // 出错了才来这儿
        }
        let snapshotView: UIView = {
            if from.transitionUsingSnapshotImage {
                return fv.snapshotView(afterScreenUpdates: false)!
            } else {
                let iv = UIImageView(image: from.transitionFromImage)
                iv.contentMode = fv.contentMode
                iv.clipsToBounds = true
                return iv
            }
        }()

        let container = transitionContext.containerView
        snapshotView.frame = container.convert(fv.frame, from: fv.superview)
        fv.isHidden = true

        toVC.view.frame = transitionContext.finalFrame(for: toVC)
        tiv.isHidden = true

        // 遮一下，
//        let mask = UIView(frame: toVC.view.frame)
//        mask.backgroundColor = .white
//        fromVC.view.addSubview(mask)

        container.insertSubview(toVC.view, belowSubview: fromVC.view)
        container.addSubview(snapshotView)

        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
            snapshotView.frame = container.convert(tiv.frame, from: tiv.superview)
            fromVC.view.alpha = 0
        }, completion: { (finish: Bool) -> Void in
            snapshotView.removeFromSuperview()
//            mask.removeFromSuperview()
            tiv.isHidden = false
            fv.isHidden = false // 万一动画被用户cancel，这个恢复的动作必不可少

            //一定要记得动画完成后执行此方法，让系统管理 navigation
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled) // 触发调用 fromVC.viewDidDisappear 方法
        })
    }
}
