//
//  SymbolKeyStore.swift
//  MYKeyboard
//
//  Created by MiY on 2017/3/24.
//  Copyright © 2017年 MiY. All rights reserved.
//

import Foundation

class SymbolKeyStore {
    
    var allSymbols: [Key] = []
    
    static let defaultKeys = ["，", "。", "？", "！", "...", "~", "'", "、"]
    
    init() {
        for symbol in SymbolKeyStore.defaultKeys {
            let key = Key(withTitle: symbol, andType: .symbol)
            allSymbols.append(key)
        }
    }
    
//    @discardableResult
//    func createKey() -> Key {
//        let defaultKeys = (" ，", " 。", " ~ ", " ？", " ！", " 、")
//        let newKey =
//            
//        
//        allSymbols.append(newKey)
//        
//        return newKey
//    }

}
