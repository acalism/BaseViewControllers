//
//  StringExtensions.swift
//  BaseViewControllers
//
//  Created by acalism on 17-4-13.
//  Copyright © 2017 acalism. All rights reserved.
//

import Foundation


// MARK: - Optional Unwrap 并转化为字符串

enum UnwrapType {
    case describing
    case reflecting
}

extension String {

    /// 将任意的Optional类型转化为String，并不会用Optional(abc)这样的包裹形式
    ///
    /// - Parameter unwrap: 需要被unwrap的类型
    /// - Parameter type: unwrap的两种方式，其中reflecting方式会更详细
    /// - Returns: 转为String后的结果
    init<Subject>(unwrap instance: Subject?, type: UnwrapType = .describing) {
        guard let i = instance else {
            self.init("nil")!
            return
        }
        switch type {
        case .describing:
            self.init(describing: i)
        case .reflecting:
            self.init(reflecting: i)
        }
    }
}

// example
//struct Point {
//    let x: Int, y: Int
//}

//let s: Point? = Point(x: 3, y: 4)
//print(String(unwrap: s))
//print(String(unwrap: s, type: .reflecting))
//print(String(describing: s))
//print(String(reflecting: s))

// 输出（test是module名字）：
// Point(x: 3, y: 4)
// test.Point(x: 3, y: 4)
// Optional(test.Point(x: 3, y: 4))
// Optional(test.Point(x: 3, y: 4))






// MARK: - String Range

//extension String {
//    func index(from: Int) -> Index {
//        return self.index(startIndex, offsetBy: from)
//    }
//
//    func substring(from: Int) -> String {
//        let fromIndex = index(from: from)
//        return substring(from: fromIndex)
//    }
//
//    func substring(to: Int) -> String {
//        let toIndex = index(from: to)
//        return substring(to: toIndex)
//    }
//
//    func substring(with r: Range<Int>) -> String {
//        let startIndex = index(from: r.lowerBound)
//        let endIndex = index(from: r.upperBound)
//        return substring(with: startIndex..<endIndex)
//    }
//}

//let str = "Hello, playground"
//print(str.substring(from: 7))         // playground
//print(str.substring(to: 5))           // Hello
//print(str.substring(with: 7..<11))    // play


// Because NSString using UTF-16, so the following answer is suitable.
// Update for Swift 3 (Xcode 8):
extension String {

    /// 将Range转为NSRange
    ///
    /// - Parameter range: 要转换的range
    /// - Returns: 转换后的结果
    func nsRange(from range: Range<String.Index>) -> NSRange {
        let from = range.lowerBound.samePosition(in: utf16)
        let to = range.upperBound.samePosition(in: utf16)
        return NSRange(location: utf16.distance(from: utf16.startIndex, to: from),
                       length: utf16.distance(from: from, to: to))
    }


    /// 将NSRange转换为Range
    ///
    /// - Parameter nsRange: 要转换的NSRange
    /// - Returns: 转换后的结果
    func range(from nsRange: NSRange) -> Range<String.Index>? {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(from16, offsetBy: nsRange.length, limitedBy: utf16.endIndex),
            let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self)
            else { return nil }
        return from ..< to
    }
}






// MARK: - NSAttributedString

extension NSAttributedString {

    /// 生成新的字符串，并将参数中的字符串追加在其后
    ///
    /// - Parameter attrString: 要追加的字符串
    /// - Returns: 拼接后的新字符串
    func appending(_ attrString: NSAttributedString) -> NSMutableAttributedString {
        let mas = NSMutableAttributedString(attributedString: self)
        mas.append(attrString)
        return mas
    }

    /// 字符串拼接
    ///
    /// - Parameters:
    ///   - lhs: 左
    ///   - rhs: 右
    /// - Returns: 拼接后的结果
    static func + (lhs: NSAttributedString, rhs: NSAttributedString) -> NSAttributedString {
        return lhs.appending(rhs)
    }
}

extension NSMutableAttributedString {
    /// 带返回值的append方法
    override func appending(_ attrString: NSAttributedString) -> NSMutableAttributedString {
        append(attrString)
        return self
    }

    /// 字符串连接
    ///
    /// - Parameters:
    ///   - lhs: 左
    ///   - rhs: 右
    /// - Returns: 字符串连接后的结果——会修改lhs，并返回lhs
    static func += (lhs: NSMutableAttributedString, rhs: NSAttributedString) -> NSMutableAttributedString {
        lhs.append(rhs)
        return lhs
    }
}




