//
//  BaseTableViewCell.swift
//  BaseViewControllers
//
//  Created by acalism on 16-9-29.
//  Copyright © 2016 acalism. All rights reserved.
//

import UIKit


class BaseTableViewCell<CellDataModel>: UITableViewCell, CellCommonPart, CellConfgigurable {

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        loadContentView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadContentView()
    }

    func loadContentView() {
        //selectionStyle = .none
    }

    var specialHighlightedArea: UIView? = nil
    var shouldTintBackgroundWhenSelected = true

    weak var tableView: UITableView? = nil
    weak var collectionView: UICollectionView? = nil
    weak var hostViewController: UIViewController? = nil // cell有自定义的action时，请遵守ScrollViewCellPerformActionHost 协议




//    override func setSelected(_ selected: Bool, animated: Bool) {
//        onSelected(selected)
//    }
//    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
//        onSelected(highlighted)
//    }
//    override var isHighlighted: Bool { // make lightgray background show immediately(使灰背景立即出现)
//        willSet {
//            onSelected(newValue)
//        }
//    }
//    override var isSelected: Bool { // keep lightGray background until unselected (保留灰背景)
//        willSet {
//            onSelected(newValue)
//        }
//    }

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
