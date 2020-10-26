//
//  LetterKeyView.swift
//  MiYKeyboard
//
//  Created by xuyang on 2020/10/22.
//  Copyright © 2020 MiY. All rights reserved.
//

import UIKit

let capitalKey = "capitalKey"                               // 大写键
let deleteKey = "deleteKey"                                 // 删除键
let numberSwitchKey = "numberSwitchKey"                     // 切换到数字键
let CHSwitchKey = "CHSwitchKey"                             // 切换到中文键
let spacekey = "spacekey"                                   // 空格键
let returnKey = "returnKey"                                 // 回车键

let symbolSwitchKey = "symbolSwitchKey"
let letterSwitchKey = "letterSwitchKey"

let letterKeyboardStartX: CGFloat = 3.0
let letterKeyboardStartY: CGFloat = 8.0
let letterKeyboardVerticalSpace: CGFloat = 10.0
let letterKeyWidth: CGFloat = LetterKeyboardView.scaleNumber(number: 32.0)
let letterKeyHeight: CGFloat = LetterKeyboardView.scaleNumber(number: 42.0)
let letterKeyboardHeight = (4 * letterKeyHeight + 3 * letterKeyboardVerticalSpace + letterKeyboardStartY)
let symbolKeyWidth: CGFloat = LetterKeyboardView.scaleNumber(number: 47.0)

let letterViewTag = 100
let numberViewTag = 200
let symbolViewTag = 300

enum LetterKeyboardType {
    case lowercaseKeyboardType                              // 小写键盘
    case uppercaseKeyboardType                              // 大写键盘
    case alwaysUppercaseKeyboardType                        // 全大写键盘
    case numbersKeyboardType                                // 数字键盘
    case symbolsKeyboardType                                // 字符键盘
}

class LetterKeyboardView: UIView {
    
    let letters = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        [capitalKey, "z", "x", "c", "v", "b", "n", "m", deleteKey],
        [numberSwitchKey, CHSwitchKey, spacekey, returnKey]
    ]
    
    let numbers = [
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
        ["-", "/", ":", ";", "(", ")", "$", "&", "@", "”"],
        [symbolSwitchKey, ".", ",", "?", "!", "'", deleteKey],
        [letterSwitchKey, spacekey, returnKey]
    ]

    let symbols = [
        ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="],
        ["_", "\\", "|", "~", "<", ">", "€", "£", "￥", "•"],
        [numberSwitchKey]
    ]
    
    // 字母特殊键盘
    let capitalKeyView = KeyView(withKey: Key(withTitle: "", andType: .capital, typeId: nil))
    let deleteKeyView = KeyView(withKey: Key(withTitle: "", andType: .backspace, typeId: nil))
    let numberSwitchKeyView = KeyView(withKey: Key(withTitle: "123", andType: .numberSwitch, typeId: nil))
    let CHSwitchKeyView = KeyView(withKey: Key(withTitle: "中", andType: .CHSwitch, typeId: nil))
    let spacekeyView = KeyView(withKey: Key(withTitle: "space", andType: .space, typeId: nil))
    let returnKeyView = KeyView(withKey: Key(withTitle: "发送", andType: .return, typeId: nil))
    
    // 数字特殊键盘
    let symbolSwitchKeyView = KeyView(withKey: Key(withTitle: "#+=", andType: .symbolSwitch, typeId: nil))
    let letterSwitchKeyView = KeyView(withKey: Key(withTitle: "ABC", andType: .numberToLetter, typeId: nil))
    let numberDeleteKeyView = KeyView(withKey: Key(withTitle: "", andType: .backspace, typeId: nil))
    let numberSpaceKeyView = KeyView(withKey: Key(withTitle: "space", andType: .space, typeId: nil))
    let numberReturnKeyView = KeyView(withKey: Key(withTitle: "发送", andType: .return, typeId: nil))
    
    // 符号键盘
    let symbolSwitchToNumberKeyView = KeyView(withKey: Key(withTitle: "123", andType: .numberSwitch, typeId: nil))
    
    weak var delegate: KeyboardViewController!
    var letterKeyViewArray = [KeyView]()                            // 字母按键视图数组
    var numberKeyViewArray = [KeyView]()                            // 数字键盘视图数组
    var thirdLineStartX: CGFloat = 0.0                              // 第三行输入按键的开始位置
    var letterKeyboardType: LetterKeyboardType! {
        willSet {
            if letterKeyboardType != newValue {
                if newValue == .lowercaseKeyboardType {
                    // 小写
                    lowercaseStatus()
                    // 切换到字母键盘
                    letterKeyboardStatus()
                } else if newValue == .uppercaseKeyboardType {
                    // 大写
                    uppercaseStatus()
                } else if newValue == .alwaysUppercaseKeyboardType {
                    // 常态大写
                    alwaysUppercaseStatus()
                } else if newValue == .numbersKeyboardType {
                    // 切换到数字键盘
                    numberKeyboardStatus()
                    // 字母键盘恢复初始化状态
                    lowercaseStatus()
                } else if newValue == .symbolsKeyboardType {
                    // 切换到符号键盘
                    symbolKeyboardStatus()
                }
            }
        }
    }
    
    
    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        // 布局视图
        prepareLettersSubview()
        prepareNumbersSubview()
        prepareSymbolsSubview()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        // 设置键盘类型
        letterKeyboardType = .lowercaseKeyboardType
    }
    
    // MARK: - 布局字母键盘
    func prepareLettersSubview() {
        // 添加事件
        CHSwitchKeyView.addTarget(self, action: #selector(tapLetterKey(_:)), for: .touchUpInside)
        deleteKeyView.addTarget(self, action: #selector(tapLetterKey(_:)), for: .touchUpInside)
        spacekeyView.addTarget(self, action: #selector(tapLetterKey(_:)), for: .touchDown)
        returnKeyView.addTarget(self, action: #selector(tapLetterKey(_:)), for: .touchUpInside)
        numberSwitchKeyView.addTarget(self, action: #selector(tapLetterKey(_:)), for: .touchUpInside)
        capitalKeyView.addTarget(self, action: #selector(tapLetterKey(_:)), for: .touchDown)
        capitalKeyView.addTarget(self, action: #selector(capitalDoubleClick), for: .touchDownRepeat)
        
        // 给视图打上标签
        let viewArray = [capitalKeyView, deleteKeyView, numberSwitchKeyView, CHSwitchKeyView, spacekeyView, returnKeyView]
        for view in viewArray {
            view.tag = letterViewTag
        }
        
        var x: CGFloat = 0
        var y: CGFloat = 0
        
        var horizontalSpace: CGFloat = 0.0
        let VerticalSpace: CGFloat = 10.0
        let cornerRadius: CGFloat = 5.0
        let sWidth = UIScreen.main.bounds.size.width
        let returnWidth: CGFloat = 88.0
        
        for rowIndex in 0..<letters.count {
            let line = letters[rowIndex]
            // 计算space
            if rowIndex == 0 {
                // 第一行的顶格显示
                x = letterKeyboardStartX
                y = letterKeyboardStartY
                horizontalSpace = (sWidth - (x * 2) - (CGFloat(line.count) * letterKeyWidth))
                horizontalSpace /= (CGFloat(line.count) - 1)
            } else if rowIndex == 1 {
                // 第二行与第一行的前两个垂直对齐
                x = (2 * letterKeyWidth + horizontalSpace) / 2.0 + letterKeyboardStartX - letterKeyWidth / 2.0
                y += letterKeyHeight + VerticalSpace
            } else if rowIndex == 2 {
                // 第三方与第二行的第二个按键开始对齐
                x = letterKeyboardStartX
                y += letterKeyHeight + VerticalSpace
            } else if rowIndex == 3 {
                x = letterKeyboardStartX
                y += letterKeyHeight + VerticalSpace
            }
            
            for itemIndex in 0..<line.count {
                let key = line[itemIndex]
                
                // 记录第三行字母开始的位置
                if rowIndex == 1 && itemIndex == 0 {
                    thirdLineStartX = x
                }
                
                if key == capitalKey {
                    addSubview(capitalKeyView)
                    capitalKeyView.layer.cornerRadius = cornerRadius
                    capitalKeyView.snp.makeConstraints { (make) in
                        make.left.equalTo(x)
                        make.top.equalTo(y)
                        make.size.equalTo(CGSize(width: letterKeyHeight, height: letterKeyHeight))
                    }
                    x = thirdLineStartX
                } else if key == deleteKey {
                    addSubview(deleteKeyView)
                    deleteKeyView.layer.cornerRadius = cornerRadius
                    deleteKeyView.snp.makeConstraints { (make) in
                        make.right.equalTo(-letterKeyboardStartX)
                        make.top.equalTo(y)
                        make.size.equalTo(CGSize(width: letterKeyHeight, height: letterKeyHeight))
                    }
                } else if key == numberSwitchKey {
                    // 切换到数字键盘的按键
                    addSubview(numberSwitchKeyView)
                    numberSwitchKeyView.layer.cornerRadius = cornerRadius
                    numberSwitchKeyView.snp.makeConstraints { (make) in
                        make.left.equalTo(x)
                        make.top.equalTo(y)
                        make.size.equalTo(CGSize(width: letterKeyHeight, height: letterKeyHeight))
                    }
                    x += horizontalSpace + letterKeyHeight
                    continue
                } else if key == CHSwitchKey {
                    // 切换到九宫格的按键
                    addSubview(CHSwitchKeyView)
                    CHSwitchKeyView.layer.cornerRadius = cornerRadius
                    CHSwitchKeyView.snp.makeConstraints { (make) in
                        make.left.equalTo(x)
                        make.top.equalTo(y)
                        make.size.equalTo(CGSize(width: letterKeyHeight, height: letterKeyHeight))
                    }
                    x += horizontalSpace + letterKeyHeight
                    continue
                } else if key == spacekey {
                    // 空格
                    addSubview(spacekeyView)
                    spacekeyView.layer.cornerRadius = cornerRadius
                    let spaceKeyWidth = sWidth - letterKeyboardStartX * 2 - letterKeyHeight * 2 - returnWidth - CGFloat(line.count - 1) * horizontalSpace
                    spacekeyView.snp.makeConstraints { (make) in
                        make.left.equalTo(x)
                        make.top.equalTo(y)
                        make.size.equalTo(CGSize(width: spaceKeyWidth, height: letterKeyHeight))
                    }
                    
                    x += horizontalSpace + spaceKeyWidth
                    continue
                } else if key == returnKey {
                    // 回车
                    addSubview(returnKeyView)
                    returnKeyView.layer.cornerRadius = cornerRadius
                    returnKeyView.snp.makeConstraints { (make) in
                        make.left.equalTo(x)
                        make.top.equalTo(y)
                        make.size.equalTo(CGSize(width: returnWidth, height: letterKeyHeight))
                    }
                } else {
                    // 字母按键
                    let keyView = KeyView(withKey: Key(withTitle: key, andType: .letter, typeId: nil))
                    addSubview(keyView)
                    keyView.layer.cornerRadius = cornerRadius
                    keyView.snp.makeConstraints { (make) in
                        make.left.equalTo(x)
                        make.top.equalTo(y)
                        make.size.equalTo(CGSize(width: letterKeyWidth, height: letterKeyHeight))
                    }
                    // 添加事件；打上标签；字母按键保存，用于大小写切换
                    keyView.addTarget(self, action: #selector(tapLetterKey(_:)), for: .touchDown)
                    letterKeyViewArray.append(keyView)
                    keyView.tag = letterViewTag
                }
                
                x += horizontalSpace + letterKeyWidth
            }
        }
    }
    
    // MARK: - 布局数字键盘
    func prepareNumbersSubview() {
        // 添加事件
        letterSwitchKeyView.addTarget(self, action: #selector(tapNumberKey(_:)), for: .touchUpInside)
        symbolSwitchKeyView.addTarget(self, action: #selector(tapNumberKey(_:)), for: .touchUpInside)
        numberDeleteKeyView.addTarget(self, action: #selector(tapNumberKey(_:)), for: .touchUpInside)
        numberReturnKeyView.addTarget(self, action: #selector(tapNumberKey(_:)), for: .touchUpInside)
        numberSpaceKeyView.addTarget(self, action: #selector(tapNumberKey(_:)), for: .touchDown)
        
        // 给视图打上标签
        let viewArray = [symbolSwitchKeyView, letterSwitchKeyView, numberDeleteKeyView, numberSpaceKeyView, numberReturnKeyView]
        for view in viewArray {
            view.tag = numberViewTag
        }
        
        var x: CGFloat = 0
        var y: CGFloat = 0
        
        var horizontalSpace: CGFloat = 0.0
        let VerticalSpace: CGFloat = 10.0
        let cornerRadius: CGFloat = 5.0
        let sWidth = UIScreen.main.bounds.size.width
        let returnWidth: CGFloat = 88.0
        
        for rowIndex in 0..<numbers.count {
            let line = numbers[rowIndex]
            // 计算space
            if rowIndex == 0 {
                // 第一行的顶格显示
                x = letterKeyboardStartX
                y = letterKeyboardStartY
                horizontalSpace = (sWidth - (x * 2) - (CGFloat(line.count) * letterKeyWidth))
                horizontalSpace /= (CGFloat(line.count) - 1)
            } else if rowIndex == 1 {
                // 第二行与第一行布局相同
                x = letterKeyboardStartX
                y += letterKeyHeight + VerticalSpace
            } else if rowIndex == 2 {
                // 第三方与第二行的第二个按键开始对齐
                x = letterKeyboardStartX
                y += letterKeyHeight + VerticalSpace
            } else if rowIndex == 3 {
                x = letterKeyboardStartX
                y += letterKeyHeight + VerticalSpace
            }
            
            for itemIndex in 0..<line.count {
                let key = line[itemIndex]
                var keyType: KeyType = .letterSymbol
                var keyViewWidth = letterKeyWidth
                let keyViewHeight = letterKeyHeight
                
                if key == symbolSwitchKey {
                    addSubview(symbolSwitchKeyView)
                    symbolSwitchKeyView.layer.cornerRadius = cornerRadius
                    symbolSwitchKeyView.snp.makeConstraints { (make) in
                        make.left.equalTo(x)
                        make.top.equalTo(y)
                        make.size.equalTo(CGSize(width: letterKeyHeight, height: letterKeyHeight))
                    }
                    
                    // 剩下的符号居中显示
                    x = thirdLineStartX + horizontalSpace + letterKeyWidth
                    continue
                } else if key == deleteKey {
                    addSubview(numberDeleteKeyView)
                    numberDeleteKeyView.layer.cornerRadius = cornerRadius
                    numberDeleteKeyView.snp.makeConstraints { (make) in
                        make.right.equalTo(-letterKeyboardStartX)
                        make.top.equalTo(y)
                        make.size.equalTo(CGSize(width: letterKeyHeight, height: letterKeyHeight))
                    }
                } else if key == letterSwitchKey {
                    // 切换到字母键盘的按键
                    addSubview(letterSwitchKeyView)
                    letterSwitchKeyView.layer.cornerRadius = cornerRadius
                    letterSwitchKeyView.snp.makeConstraints { (make) in
                        make.left.equalTo(x)
                        make.top.equalTo(y)
                        make.size.equalTo(CGSize(width: letterKeyHeight, height: letterKeyHeight))
                    }
                    x += horizontalSpace + letterKeyHeight
                    continue
                } else if key == spacekey {
                    // 空格
                    addSubview(numberSpaceKeyView)
                    numberSpaceKeyView.layer.cornerRadius = cornerRadius
                    let spaceKeyWidth = sWidth - letterKeyboardStartX * 2 - letterKeyHeight - returnWidth - 2 * horizontalSpace
                    numberSpaceKeyView.snp.makeConstraints { (make) in
                        make.left.equalTo(x)
                        make.top.equalTo(y)
                        make.size.equalTo(CGSize(width: spaceKeyWidth, height: letterKeyHeight))
                    }
                    
                    x += horizontalSpace + spaceKeyWidth
                    continue
                } else if key == returnKey {
                    // 回车
                    addSubview(numberReturnKeyView)
                    numberReturnKeyView.layer.cornerRadius = cornerRadius
                    numberReturnKeyView.snp.makeConstraints { (make) in
                        make.left.equalTo(x)
                        make.top.equalTo(y)
                        make.size.equalTo(CGSize(width: returnWidth, height: letterKeyHeight))
                    }
                } else {
                    // 数字、符号按键
                    if rowIndex == 0 {
                        keyType = .number
                    } else if rowIndex == 2 && itemIndex > 0 {
                        keyViewWidth = symbolKeyWidth
                    }
                    
                    let keyView = KeyView(withKey: Key(withTitle: key, andType: keyType, typeId: nil))
                    addSubview(keyView)
                    keyView.layer.cornerRadius = cornerRadius
                    keyView.snp.makeConstraints { (make) in
                        make.left.equalTo(x)
                        make.top.equalTo(y)
                        make.size.equalTo(CGSize(width: keyViewWidth, height: keyViewHeight))
                    }
                    
                    keyView.tag = numberViewTag
                    keyView.addTarget(self, action: #selector(tapNumberKey(_:)), for: .touchDown)
                    if rowIndex < 2 {
                        numberKeyViewArray.append(keyView)
                    }
                }
                
                x += horizontalSpace + keyViewWidth
            }
        }
        
        // 添加切换到符号键盘的按键
        numberKeyViewArray.append(symbolSwitchKeyView)
    }
    
    // MARK: - 布局符号键盘
    func prepareSymbolsSubview() {
        // 添加事件
        symbolSwitchToNumberKeyView.addTarget(self, action: #selector(tapSymbolKey(_:)), for: .touchUpInside)
        symbolSwitchToNumberKeyView.tag = symbolViewTag
        
        var x: CGFloat = 0
        var y: CGFloat = 0
        
        var horizontalSpace: CGFloat = 0.0
        let VerticalSpace: CGFloat = 10.0
        let cornerRadius: CGFloat = 5.0
        let sWidth = UIScreen.main.bounds.size.width
        
        for rowIndex in 0..<symbols.count {
            let line = symbols[rowIndex]
            // 计算space
            if rowIndex == 0 {
                // 第一行的顶格显示
                x = letterKeyboardStartX
                y = letterKeyboardStartY
                horizontalSpace = (sWidth - (x * 2) - (CGFloat(line.count) * letterKeyWidth))
                horizontalSpace /= (CGFloat(line.count) - 1)
            } else if rowIndex == 1 {
                // 第二行与第一行布局相同
                x = letterKeyboardStartX
                y += letterKeyHeight + VerticalSpace
            } else if rowIndex == 2 {
                // 第三方与第二行的第二个按键开始对齐
                x = letterKeyboardStartX
                y += letterKeyHeight + VerticalSpace
            }
            
            for itemIndex in 0..<line.count {
                let key = line[itemIndex]
                let keyViewWidth = letterKeyWidth
                let keyViewHeight = letterKeyHeight
                
                if key == numberSwitchKey {
                    addSubview(symbolSwitchToNumberKeyView)
                    symbolSwitchToNumberKeyView.layer.cornerRadius = cornerRadius
                    symbolSwitchToNumberKeyView.snp.makeConstraints { (make) in
                        make.left.equalTo(x)
                        make.top.equalTo(y)
                        make.size.equalTo(CGSize(width: letterKeyHeight, height: letterKeyHeight))
                    }
                } else {
                    // 符号按键
                    let keyView = KeyView(withKey: Key(withTitle: key, andType: .letterSymbol, typeId: nil))
                    addSubview(keyView)
                    keyView.layer.cornerRadius = cornerRadius
                    keyView.snp.makeConstraints { (make) in
                        make.left.equalTo(x)
                        make.top.equalTo(y)
                        make.size.equalTo(CGSize(width: keyViewWidth, height: keyViewHeight))
                    }
                    
                    keyView.tag = symbolViewTag
                    keyView.addTarget(self, action: #selector(tapSymbolKey(_:)), for: .touchDown)
                }
                
                x += horizontalSpace + keyViewWidth
            }
        }
    }
    
    // MARK: - 事件处理
    // 处理字母输入
    @objc func tapLetterKey(_ sender: KeyView) {
        let proxy = (delegate.textDocumentProxy) as UITextDocumentProxy
        
        let type = sender.key.type
        switch type {
        case .letter:
            if let letter = sender.titleLabel.text {
                proxy.insertText(letter)
            }
            
            // 如果键盘类型为大写键盘类型，则点击之后，转为小写
            if letterKeyboardType == .uppercaseKeyboardType {
                letterKeyboardType = .lowercaseKeyboardType
            }
        case .numberSwitch:
            // 切换到数字键盘
            letterKeyboardType = .numbersKeyboardType
        case .capital:
            // 键盘大小写
            perform(#selector(capitalSingleClick), with: nil, afterDelay: 0.2)
        case .CHSwitch:
            // 切换回九宫格键盘
            delegate.keyboardType = .pinyin
        case .space:
            proxy.insertText(" ")
        case .return:
            proxy.insertText("\n")
        case .backspace:
            proxy.deleteBackward()
        default:
            break
        }
    }
    
    // 处理字母输入
    @objc func tapNumberKey(_ sender: KeyView) {
        let proxy = (delegate.textDocumentProxy) as UITextDocumentProxy
        
        let type = sender.key.type
        switch type {
        case .numberToLetter:
            // 切换为小写键盘
            letterKeyboardType = .lowercaseKeyboardType
        case .symbolSwitch:
            // 切换为符号键盘
            letterKeyboardType = .symbolsKeyboardType
        case .number:
            // 输入数字
            if let letter = sender.titleLabel.text {
                proxy.insertText(letter)
            }
        case .letterSymbol:
            // 输入符号
            if let letter = sender.titleLabel.text {
                proxy.insertText(letter)
            }
        case .backspace:
            proxy.deleteBackward()
        case .return:
            proxy.insertText("\n")
        case .space:
            proxy.insertText(" ")
        default:
            break
        }
    }
    
    // 处理符号输入
    @objc func tapSymbolKey(_ sender: KeyView) {
        let proxy = (delegate.textDocumentProxy) as UITextDocumentProxy
        
        let type = sender.key.type
        switch type {
        case .letterSymbol:
            // 输入符号
            if let letter = sender.titleLabel.text {
                proxy.insertText(letter)
            }
        case .numberSwitch:
            // 切换为数字键盘
            letterKeyboardType = .numbersKeyboardType
        default:
            break
        }
    }
    
    // 字母键盘大小写
    @objc func capitalSingleClick() {
        if letterKeyboardType == .lowercaseKeyboardType {
            // 变成大写键盘
            letterKeyboardType = .uppercaseKeyboardType
        } else if letterKeyboardType == .uppercaseKeyboardType || letterKeyboardType == .alwaysUppercaseKeyboardType {
            // 变成小写键盘
            letterKeyboardType = .lowercaseKeyboardType
        }
    }
    
    // 字母键盘锁定大写
    @objc func capitalDoubleClick() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(capitalSingleClick), object: nil)
        letterKeyboardType = .alwaysUppercaseKeyboardType
    }
}

extension LetterKeyboardView {
    
    /// 根据屏幕宽度缩放大小
    static func scaleNumber(number: CGFloat) -> CGFloat {
        return number / 375.0 * UIScreen.main.bounds.size.width
    }
    
    // 小写键盘状态
    func lowercaseStatus() {
        for key in letterKeyViewArray {
            if let letter = key.titleLabel.text {
                key.titleLabel.text = letter.lowercased()
            }
        }
        //修改大小写按键视图image
        capitalKeyView.key.capitalType = .lowercaseType
        capitalKeyView.setNeedsLayout()
    }
    
    // 大写键盘状态
    func uppercaseStatus() {
        for key in letterKeyViewArray {
            if let letter = key.titleLabel.text {
                key.titleLabel.text = letter.uppercased()
            }
        }
        //修改大小写按键视图image
        capitalKeyView.key.capitalType = .uppercaseType
        capitalKeyView.setNeedsLayout()
    }
    
    // 常态大写状态
    func alwaysUppercaseStatus() {
        for key in letterKeyViewArray {
            if let letter = key.titleLabel.text {
                key.titleLabel.text = letter.uppercased()
            }
        }
        //修改大小写按键视图image
        capitalKeyView.key.capitalType = .alwaysUppercaseType
        capitalKeyView.setNeedsLayout()
    }
    
    // 显示数字键盘
    func numberKeyboardStatus() {
        for subview in subviews {
            subview.isHidden = (subview.tag != numberViewTag)
        }
    }
    
    // 显示字母键盘
    func letterKeyboardStatus() {
        for subview in subviews {
            subview.isHidden = (subview.tag != letterViewTag)
        }
    }
    
    // 显示符号键盘
    func symbolKeyboardStatus() {
        for subview in subviews {
            if subview.tag == symbolViewTag {
                subview.isHidden = false
            } else if subview.tag == letterViewTag {
                subview.isHidden = true
            } else if subview.tag == numberViewTag {
                // 符号键盘显示时，只隐藏数字键盘前两排
                subview.isHidden = numberKeyViewArray.contains(subview as! KeyView)
            }
        }
    }
}
