//
//  KeyboardModel.swift
//  MYKeyboard
//
//  Created by MiY on 2017/3/22.
//  Copyright © 2017年 MiY. All rights reserved.
//

import Foundation

enum KeyType {
    case normal         //9宫格普通按键
    case symbol         //符号
    case backspace      //删除
    case space          //空格
    case `return`       //回车
    case nextKeyboard   //切换输入法
    case changeToNumber //切换到数字输入面板
    case changeToSymbol //切换到符号面板
    case number         //数字
    case dismiss        //关闭键盘
    case moreWords      //更多候选词
    case pinyin         //拼音
    case reType         //重输
    case changeToNormal //返回
    
    case letter                 // 字母
    case capital                // 大小写
    case numberSwitch           // 切换到数字键盘
    case chSwitch               // 切换到中文键盘
    case changeToLetter         // 切换到字母键盘
    
    case letterSymbol           // 字符
    case symbolSwitch           // 切换到符号键盘
    case numberToLetter         // 数字键盘切换到字母键盘
}

enum CapitalType {
    case lowercaseType
    case uppercaseType
    case alwaysUppercaseType
}

class Key {
    
    let title: String?                                  // 按键显示文本
    let type: KeyType                                   // 按键类型
    var capitalType: CapitalType = .lowercaseType       // 字母默认小写
    let typeId: String?                                 // 九宫格输入法中的数字标识
    var outputText: String?                             // 按下之后，需要显示在输入框中的文本
    var index: Int? = nil                               // 用来选拼音
    
    init(withTitle title:String, andType type: KeyType, typeId: String? = nil) {
        
        self.typeId = typeId
        self.title = title
        self.type = type
        createOutputTextWithType(type)
    }
    
    func createOutputTextWithType(_ type: KeyType) {
        
        switch type {
//        case .normal:
//            outputText = title
        case .symbol:
            outputText = title
        case .number:
            outputText = title

        default:
            outputText = nil
        }
    }
}







