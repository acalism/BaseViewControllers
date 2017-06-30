//
//  BaseCollectionViewController.swift
//  BaseViewControllers
//
//  Created by acalism on 16-8-4.
//  Copyright © 2016年 acalism. All rights reserved.
//

import UIKit

enum ReuseIdentifier: String {
    case cell
    case header
    case footer

    case cell2nd
    case cell3rd
    case cell4th
    case cell5th

    case header2nd
    case header3rd
    case header4th
    case header5th

    case footer2nd
    case footer3rd
    case footer4th
    case footer5th
}


extension UITableView {
    func dequeueReusableCell(withIdentifier identifier: ReuseIdentifier, for indexPath: IndexPath) -> UITableViewCell {
        return dequeueReusableCell(withIdentifier: identifier.rawValue, for: indexPath)
    }
    func dequeueReusableHeaderFooterView(withIdentifier identifier: ReuseIdentifier) -> UITableViewHeaderFooterView? {
        return dequeueReusableHeaderFooterView(withIdentifier: identifier.rawValue)
    }


    func register(_ cellClass: AnyClass?, forCellReuseIdentifier identifier: ReuseIdentifier) {
        register(cellClass, forCellReuseIdentifier: identifier.rawValue)
    }
    func register(_ aClass: AnyClass?, forHeaderFooterViewReuseIdentifier identifier: ReuseIdentifier) {
        register(aClass, forHeaderFooterViewReuseIdentifier: identifier.rawValue)
    }
}


extension UICollectionView {
    func register(_ cellClass: AnyClass?, forCellWithReuseIdentifier identifier: ReuseIdentifier) {
        register(cellClass, forCellWithReuseIdentifier: identifier.rawValue)
    }
    func register(_ viewClass: AnyClass?, forSupplementaryViewOfKind elementKind: String, withReuseIdentifier identifier: ReuseIdentifier) {
        register(viewClass, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: identifier.rawValue)
    }


    func dequeueReusableCell(reuseIdentifier identifier: ReuseIdentifier, for indexPath: IndexPath) -> UICollectionViewCell {
        return dequeueReusableCell(withReuseIdentifier: identifier.rawValue, for: indexPath)
    }
    func dequeueReusableSupplementaryView(ofKind elementKind: String, withReuseIdentifier identifier: ReuseIdentifier, for indexPath: IndexPath) -> UICollectionReusableView {
        return dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: identifier.rawValue, for: indexPath)
    }
}





class BaseCollectionViewController: BaseScrollViewController {

    let collectionView: UICollectionView
    var collectionViewLayout: UICollectionViewLayout

    var clearsSelectionOnViewWillAppear = true

    init(collectionViewLayout: UICollectionViewLayout) {
        self.collectionViewLayout = collectionViewLayout
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        useDefaultScrollView = false

        super.loadView()

        scrollView = collectionView

        collectionView.backgroundColor = UIColor.clear
        collectionView.frame = view.bounds
        view.addSubview(collectionView)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.dataSource = self
        collectionView.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations

//        collectionView.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: .cell)
//        collectionView.registerClass(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: .header)
//        collectionView.registerClass(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: .footer)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForground(_:)), name: .UIApplicationWillEnterForeground, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        clearSelection(animated: animated)
    }

    override func reloadContent(animated: Bool = false) {
        super.reloadContent(animated: animated)
        collectionView.reloadData()
    }

    func appWillEnterForground(_ noti: Notification) {
        if appeared {
            clearSelection(animated: true)
        }
    }

    func clearSelection(animated: Bool) {
        if let ipArray = collectionView.indexPathsForSelectedItems, clearsSelectionOnViewWillAppear {
            for ip in ipArray {
                collectionView.deselectItem(at: ip, animated: animated)
            }
        }
    }
}


// MARK: UICollectionViewDataSource

extension BaseCollectionViewController: UICollectionViewDataSource {
    func numberOfSections(in cv: UICollectionView) -> Int {
        return 1
    }


    func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }

    func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        fatalError("must be overriden")
    }
    func collectionView(_ cv: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
//        if kind == UICollectionElementKindSectionHeader {
//            return cv.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: .header, forIndexPath: indexPath)
//        } else if kind == UICollectionElementKindSectionFooter {
//            return cv.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: .footer, forIndexPath: indexPath)
//        }
        return UICollectionReusableView()
    }
}




// MARK: UICollectionViewDelegate

extension BaseCollectionViewController: UICollectionViewDelegate {

    // Uncomment this method to specify if the specified item should be highlighted during tracking
    func collectionView(_ cv: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }



    // Uncomment this method to specify if the specified item should be selected
    func collectionView(_ cv: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ cv: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //
    }

    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    func collectionView(_ cv: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    func collectionView(_ cv: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    func collectionView(_ cv: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        //
    }
}
