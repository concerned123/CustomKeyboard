//
//  KeyboardViewController.swift
//  MiYKeyboard
//
//  Created by MiY on 2017/3/20.
//  Copyright © 2017年 MiY. All rights reserved.
//

import UIKit
import SnapKit

enum KeyboardType: Int {
    case pinyin = 0             // 九宫格拼音键盘
    case letter = 1             // 字母键盘
}

class KeyboardViewController: UIInputViewController {

    var letterKeyboardView = LetterKeyboardView()                           // 字母键盘
    var pinYinKeyboardView = PinYinKeyboardView(frame: CGRect.zero)         // 九宫格拼音键盘
    
    var keyboardType: KeyboardType! {
        willSet {
            if keyboardType != newValue {
                if newValue == .pinyin {
                    // 九宫格拼音键盘
                    self.inputView?.addSubview(pinYinKeyboardView)
                    pinYinKeyboardView.delegate = self
                    pinYinKeyboardView.snp.remakeConstraints({ (make) -> Void in
                        make.left.right.bottom.top.equalToSuperview()
                        make.height.greaterThanOrEqualTo(216+bannerHeight).priority(999)
                    })
                    letterKeyboardView.removeFromSuperview()
                } else if newValue == .letter {
                    // 字母键盘
                    self.inputView?.addSubview(letterKeyboardView)
                    letterKeyboardView.delegate = self
                    letterKeyboardView.snp.remakeConstraints { (make) in
                        make.left.right.bottom.top.equalToSuperview()
                        make.height.equalTo(letterKeyboardHeight).priority(999)
                    }
                    pinYinKeyboardView.reset()
                    pinYinKeyboardView.removeFromSuperview()
                }
            }
        }
    }
         
    override func updateViewConstraints() {
        super.updateViewConstraints()
        // Add custom view sizing constraints here
    }
    
    // MARK: View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // 默认初始化为拼音输入法
        keyboardType = .pinyin
        
        // 启动
        CommonTable.start()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated
    }
    
    override func textWillChange(_ textInput: UITextInput?) {
        // The app is about to change the document's contents. Perform any preparation here.
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        // The app has just changed the document's contents, the document context has been updated.
        
//        var textColor: UIColor
//        let proxy = self.textDocumentProxy
//        if proxy.keyboardAppearance == UIKeyboardAppearance.dark {
//            textColor = UIColor.white
//        } else {
//            textColor = UIColor.black
//        }
//        self.nextKeyboardButton.setTitleColor(textColor, for: [])
    }
}


