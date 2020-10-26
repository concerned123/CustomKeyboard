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

enum LetterKeyboardType {
    case lowercaseKeyboardType                              // 小写键盘
    case uppercaseKeyboardType                              // 大写键盘
    case alwaysUppercaseKeyboardType                        // 全大写键盘
    case numbersKeyboardType                                // 数字键盘
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
    
    let capitalKeyView = KeyView(withKey: Key(withTitle: "", andType: .capital, typeId: nil))
    let deleteKeyView = KeyView(withKey: Key(withTitle: "", andType: .backspace, typeId: nil))
    
    let numberSwitchKeyView = KeyView(withKey: Key(withTitle: "123", andType: .numberSwitch, typeId: nil))
    let CHSwitchKeyView = KeyView(withKey: Key(withTitle: "中", andType: .CHSwitch, typeId: nil))
    let spacekeyView = KeyView(withKey: Key(withTitle: "space", andType: .space, typeId: nil))
    let returnKeyView = KeyView(withKey: Key(withTitle: "发送", andType: .return, typeId: nil))
    
    weak var delegate: KeyboardViewController!
    var letterKeyViewArray = [KeyView]()                            // 字母按键视图数组
    var letterKeyboardType: LetterKeyboardType! {
        willSet {
            if letterKeyboardType != newValue {
                if newValue == .lowercaseKeyboardType {
                    // 小写
                    for key in letterKeyViewArray {
                        if let letter = key.titleLabel.text {
                            key.titleLabel.text = letter.lowercased()
                        }
                    }
                    //修改大小写按键视图image
                    capitalKeyView.key.capitalType = .lowercaseType
                } else if newValue == .uppercaseKeyboardType || newValue == .alwaysUppercaseKeyboardType {
                    // 大写
                    for key in letterKeyViewArray {
                        if let letter = key.titleLabel.text {
                            key.titleLabel.text = letter.uppercased()
                        }
                    }
                }
                
                //修改大小写按键视图image
                if newValue == .uppercaseKeyboardType {
                    capitalKeyView.key.capitalType = .uppercaseType
                } else if newValue == .alwaysUppercaseKeyboardType {
                    capitalKeyView.key.capitalType = .alwaysUppercaseType
                } else if newValue == .lowercaseKeyboardType {
                    capitalKeyView.key.capitalType = .lowercaseType
                }
                capitalKeyView.setNeedsLayout()
            }
        }
    }
    
    
    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        letterKeyboardType = .lowercaseKeyboardType
        prepareLettersSubview()
        
        CHSwitchKeyView.addTarget(self, action: #selector(changeKeyboardTypeToPinYin), for: UIControl.Event.touchUpInside)
        deleteKeyView.addTarget(self, action: #selector(tapLetterKey(_:)), for: .touchUpInside)
        spacekeyView.addTarget(self, action: #selector(tapLetterKey(_:)), for: .touchDown)
        returnKeyView.addTarget(self, action: #selector(tapLetterKey(_:)), for: .touchUpInside)
        capitalKeyView.addTarget(self, action: #selector(tapLetterKey(_:)), for: .touchDown)
//        capitalKeyView.addTarget(self, action: #selector(tapLetterKey(_:)), for: .touchDownRepeat)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 视图布局
    func prepareLettersSubview() {
    
        var x: CGFloat = 0
        var y: CGFloat = 0
        
        var horizontalSpace: CGFloat = 0.0
        let VerticalSpace: CGFloat = 10.0
        
        let cornerRadius: CGFloat = 5.0
        var thirdLineStartX: CGFloat = 0.0

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
                    
                    keyView.addTarget(self, action: #selector(tapLetterKey(_:)), for: .touchDown)
                    letterKeyViewArray.append(keyView)
                }
                
                x += horizontalSpace + letterKeyWidth
            }
        }
    }
    
    /// 布局数字键盘
    func prepareNumbersSubview() {
        
    }
    
    /// 根据屏幕宽度缩放大小
    static func scaleNumber(number: CGFloat) -> CGFloat {
        return number / 375.0 * UIScreen.main.bounds.size.width
    }
    
    // MARK: - 事件处理
    // 切换键盘类型
    @objc func changeKeyboardTypeToPinYin() {
        delegate.keyboardType = .pinyin
    }
    
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
        case .backspace:
            proxy.deleteBackward()
        case .numberSwitch:
            debugPrint("")
        case .capital:
            if letterKeyboardType == .lowercaseKeyboardType {
                // 变成大写键盘
                letterKeyboardType = .uppercaseKeyboardType
            } else if letterKeyboardType == .uppercaseKeyboardType || letterKeyboardType == .alwaysUppercaseKeyboardType {
                // 变成小写键盘
                letterKeyboardType = .lowercaseKeyboardType
            }
        case .space:
            proxy.insertText(" ")
        case .return:
            proxy.insertText("\n")
        default:
            break
        }
        
        
    }
    
}
