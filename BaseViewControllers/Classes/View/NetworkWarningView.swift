//
//  NetworkWarningView.swift
//  BaseViewControllers
//
//  Created by acalism on 16-9-26.
//  Copyright © 2016 acalism. All rights reserved.
//

import UIKit


protocol NetworkWarningViewDelegate: class {
    func errorChanged(oldValue: NetworkWarningView.WarningType, newValue: NetworkWarningView.WarningType)
    func retryLoad()
}

class NetworkWarningView: UIView {

    enum WarningType {
        case noError, loading, loadFailed
    }

    var warningType: WarningType = .noError {
        didSet {
            guard oldValue != warningType else { return }

            delegate?.errorChanged(oldValue: oldValue, newValue: warningType)

            switch warningType {

            case .noError:
                setWarning(hidden: true)

            case .loading:
                setWarning(hidden: false)
                tipLabel.text = "正在加载中..."
                activityIndicator.startAnimating()
                actionButton.isEnabled = false
                setNeedsLayout()

            case .loadFailed:
                setWarning(hidden: false)
                tipLabel.text = "数据加载失败"
                activityIndicator.stopAnimating()
                actionButton.isEnabled = true
                setNeedsLayout()

            }
        }
    }

    func setWarning(hidden: Bool) {
        tipLabel.isHidden = hidden
        actionButton.isHidden = hidden
        self.isHidden = hidden
    }

    let tipLabel = UILabel()
    let actionButton = UIButton(type: .custom)
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    fileprivate let buttonSize = CGSize(width: 80, height: 30)
    fileprivate let vDistance: CGFloat = 20

    weak var delegate: NetworkWarningViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.clear

        tipLabel.text = "数据加载失败"
        tipLabel.textColor = UIColor(rgb: 0xB2B2B2)
        tipLabel.font = UIFont.systemFont(ofSize: 18)

        actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        actionButton.setTitleColor(tipLabel.textColor, for: UIControlState())
        actionButton.setTitle("重试", for: UIControlState())
        actionButton.setTitle("", for: .disabled)

        actionButton.layer.masksToBounds = true
        actionButton.layer.cornerRadius = 6 // buttonSize.height / 2
        actionButton.layer.borderWidth = 1
        actionButton.layer.borderColor = tipLabel.textColor.cgColor

        setWarning(hidden: true)

        for v in [tipLabel, actionButton, activityIndicator] as [UIView] {
            addSubview(v)
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        tipLabel.sizeToFit()
        tipLabel.frame.origin = CGPoint(x: max(0, (buttonSize.width - tipLabel.frame.width) / 2), y: 0) // 水平居中
        actionButton.frame = CGRect(origin: CGPoint(x: tipLabel.center.x - buttonSize.width / 2, y: tipLabel.frame.maxY + vDistance), size: buttonSize) // 水平居中
        activityIndicator.center = actionButton.center
    }
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return intrinsicContentSize
    }
    override var intrinsicContentSize : CGSize {
        let size = tipLabel.intrinsicContentSize
        return CGSize(width: max(size.width, buttonSize.width), height: size.height + vDistance + buttonSize.height)
    }
}
