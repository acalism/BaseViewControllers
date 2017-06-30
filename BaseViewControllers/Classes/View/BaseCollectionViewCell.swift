//
//  BaseCollectionViewCell.swift
//  BaseViewControllers
//
//  Created by acalism on 16-9-26.
//  Copyright © 2016 acalism. All rights reserved.
//

import UIKit


class BaseCollectionViewCell<CellDataModel>: UICollectionViewCell, CellCommonPart, CellConfgigurable {

    var separatorInset = UIEdgeInsets.zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadContentView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadContentView()
    }

    func loadContentView() {
        //
    }

//    override func prepareForReuse() {
//        super.prepareForReuse()
//        setNeedsLayout() // reuse时不一定需要layout
//    }

    weak var tableView: UITableView? = nil
    weak var collectionView: UICollectionView? = nil
    weak var hostViewController: UIViewController? = nil // cell有自定义的action时，请遵守 ScrollViewCellPerformActionHost 协议



    // MARK: - Selection, highlighted

    var shouldTintBackgroundWhenSelected = true
    var specialHighlightedArea: UIView?

    override var isHighlighted: Bool { // make lightgray background show immediately(使灰背景立即出现)
        willSet {
            onSelected(newValue)
        }
    }
    override var isSelected: Bool { // keep lightGray background until unselected (保留灰背景)
        willSet {
            onSelected(newValue)
        }
    }

    func onSelected(_ newValue: Bool) {
        defaultOnSelected(newValue)
    }

    // MARK: - CellConfigurable

    var model: CellDataModel? = nil

    /// override 时需调用super
    func configure(model: CellDataModel?) {
        self.model = model
    }
}

