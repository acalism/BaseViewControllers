//
//  CellProtocol.swift
//  BaseViewControllers
//
//  Created by acalism on 17-4-17.
//  Copyright © 2017 acalism. All rights reserved.
//

import UIKit



extension UIColor {
    convenience init(rgb: Int, alpha a: CGFloat = 1.0) {
        self.init(red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0, green: CGFloat((rgb & 0xFF00) >> 8) / 255.0, blue: CGFloat(rgb & 0xFF) / 255.0, alpha: a)
    }
}




// MARK: - Common Part of UITableView and UICollectionView

protocol CellCommonPart: class {

    // UITableViewCell 和 UICollectionViewCell 共有的

    var contentView: UIView { get } // add custom subviews to the cell's contentView
    var isSelected: Bool { get set }
    var isHighlighted: Bool { get set }
    var backgroundView: UIView? { get set }
    var selectedBackgroundView: UIView? { get set }
    func prepareForReuse()


    // 下面是acalism为这两种cell添加的

    var shouldTintBackgroundWhenSelected: Bool { get set }
    var specialHighlightedArea: UIView? { get set }

    weak var tableView: UITableView? { get set }
    weak var collectionView: UICollectionView? { get set }
    weak var hostViewController: UIViewController? { get set } // 有cell附带的action时，请遵守 ScrollViewCellPerformActionHost 协议

    func loadContentView() // 相当于UIViewController的loadView()方法

    func onSelected(_ newValue: Bool)
}

extension CellCommonPart {
    func defaultOnSelected(_ newValue: Bool) {
        guard selectedBackgroundView == nil else { return }
        if shouldTintBackgroundWhenSelected {
            contentView.backgroundColor = newValue ? cellHighlightedColor : UIColor.clear
        }
        if let sa = specialHighlightedArea {
            sa.backgroundColor = newValue ? UIColor.black.withAlphaComponent(0.4) : UIColor.clear
        }
    }
}

/// cell被选中时contentView的背景色，也是separatorLine的颜色。
/// 注意：覆盖在content上的选中色，得带alpha值，否则会盖住content
let cellHighlightedColor = UIColor(rgb: 0xD8D8D8)





protocol CellConfgigurable {
    associatedtype CellDataModel
    var model: CellDataModel? { get set }
    func configure(model: CellDataModel?) // 填数据，建议在末尾调用setNeedsLayout()方法
}





// MARK: - cell size
/// cell大小为静态时，直接向cell类查询大小
protocol StaticSizedCell: class {
    static var size: CGSize { get }
}
//extension StaticSizedCell {
//    static var size: CGSize {
//        return CGSize(width: 44, height: 44)
//    }
//}






/// cell大小为动态时，向cell实例查询大小
protocol DynamicSizedCell: class {
    var size: CGSize { get }
    func resize(to: CGSize)
}
//extension DynamicSizedCell {
//    var size: CGSize {
//        return CGSize(width: 44, height: 44)
//    }
//}




protocol RemovalbeCell: class {
    func remove()
}





// MARK: - Cell Action


/// 每个cell可以定义多个Action
enum ActionInCell {
    case action0
    case action1
    case action2
    case action3
}


protocol ScrollViewCellPerformActionHost: class {
    func tableView(_ sv: UITableView, perform action: ActionInCell, at cell: UITableViewCell, sender: Any?)
    func collectionView(_ sv: UICollectionView, perform action: ActionInCell, at cell: UICollectionViewCell, sender: Any?)
}


// 扩展使这两个方法变成可选的：TableViewController只需实现第1个方法，而CollectionViewController只需实现第2个方法
extension ScrollViewCellPerformActionHost {
    func tableView(_ sv: UITableView, perform action: ActionInCell, at cell: UITableViewCell, sender: Any?) {}
    func collectionView(_ sv: UICollectionView, perform action: ActionInCell, at cell: UICollectionViewCell, sender: Any?) {}
}
