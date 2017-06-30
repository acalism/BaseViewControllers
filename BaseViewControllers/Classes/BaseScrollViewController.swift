//
//  BaseScrollViewController.swift
//  BaseViewControllers
//
//  Created by acalism on 16-9-25.
//  Copyright © 2016 acalism. All rights reserved.
//

import UIKit

fileprivate let noMoreDataTitle: String = "" // 已经到底部啦

class BaseScrollViewController: BaseViewController, UIScrollViewDelegate {

    var scrollView = UIScrollView()

    var useDefaultScrollView = true

    var positionsOfRefreshControl: UIRectEdge = UIRectEdge() {
        didSet { // 允许oldValue和新值相同
            if positionsOfRefreshControl.contains(.top) {
                // add top pull control if needed
            } else {
                // remove top pull control if needed
            }

            if positionsOfRefreshControl.contains(.bottom) {
                // add bottom pull control if needed
            } else {
                // remove bottom pull control if needed
            }
        }
    }

    override func loadView() {
        super.loadView()

        guard useDefaultScrollView else {
            return
        }
        scrollView.backgroundColor = UIColor.clear
        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(scrollView)
        scrollView.delegate = self
    }

//    override func clearContent(animated: Bool) {
//        super.clearContent(animated: animated)
//        for vc in childViewControllers {
//            vc.willMove(toParentViewController: nil)
//            vc.view.removeFromSuperview()
//            vc.removeFromParentViewController()
//        }
//        for v in scrollViewContentView.subviews {
//            v.removeFromSuperview()
//        }
//    }

    fileprivate var oldPositionsOfRefreshControl: UIRectEdge = UIRectEdge()

    override func errorChanged(oldValue: NetworkWarningView.WarningType, newValue: NetworkWarningView.WarningType) {
        super.errorChanged(oldValue: oldValue, newValue: newValue)
        if oldValue == .noError {
            oldPositionsOfRefreshControl = positionsOfRefreshControl
            positionsOfRefreshControl = UIRectEdge()
        } else {
            positionsOfRefreshControl = oldPositionsOfRefreshControl
        }
    }

    // MARK: - UIScrollViewDelegate

//    func scrollViewDidScroll(_ sv: UIScrollView) // any offset changes
//    {
//        //
//    }
//    func scrollViewDidZoom(_ sv: UIScrollView) // any zoom scale changes
//    {
//        //
//    }
//
//    // called on start of dragging (may require some time and or distance to move)
//    func scrollViewWillBeginDragging(_ sv: UIScrollView)
//    {
//        //
//    }
//    // called on finger up if the user dragged. velocity is in points/millisecond. targetContentOffset may be changed to adjust where the scroll view comes to rest
//    func scrollViewWillEndDragging(_ sv: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>)
//    {
//        //
//    }
//    // called on finger up if the user dragged. decelerate is true if it will continue moving afterwards
//    func scrollViewDidEndDragging(_ sv: UIScrollView, willDecelerate decelerate: Bool)
//    {
//        //
//    }
//
//    func scrollViewWillBeginDecelerating(_ sv: UIScrollView) // called on finger up as we are moving
//    {
//        //
//    }
//    func scrollViewDidEndDecelerating(_ sv: UIScrollView) // called when scroll view grinds to a halt
//    {
//        //
//    }
//
//    func scrollViewDidEndScrollingAnimation(_ sv: UIScrollView) // called when setContentOffset/scrollRectVisible:animated: finishes. not called if not animating
//    {
//        //
//    }
//
//    func viewForZooming(in sv: UIScrollView) -> UIView? // return a view that will be scaled. if delegate returns nil, nothing happens
//    {
//        return nil
//    }
//    func scrollViewWillBeginZooming(_ sv: UIScrollView, with view: UIView?) // called before the scroll view begins zooming its content
//    {
//        //
//    }
//    func scrollViewDidEndZooming(_ sv: UIScrollView, with view: UIView?, atScale scale: CGFloat) // scale between minimum and maximum. called after any 'bounce' animations
//    {
//        //
//    }
//
//    func scrollViewShouldScrollToTop(_ sv: UIScrollView) -> Bool // return a yes if you want to scroll to the top. if not defined, assumes YES
//    {
//        return true
//    }
//    func scrollViewDidScrollToTop(_ sv: UIScrollView) // called when scrolling animation finished. may be called immediately if already at top
//    {
//        //
//    }
}
