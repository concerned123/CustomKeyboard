//
//  PinyinStore.swift
//  MYKeyboard
//
//  Created by MiY on 2017/3/29.
//  Copyright © 2017年 MiY. All rights reserved.
//

import Foundation

class PinyinStore {
    
    var id: String = "" {
        didSet {
            // 搜索缓存
            if needSearchHistory {
                isInHistory = findIdInHistory(id)
            }
            if isInHistory {
//                let value = historyDictionary?.value(forKey: id) as? Array<[String]>
//                pinyinHistory = value![0][0]
//                words = value![1]
//                historyCount = words.count
                
                if let cache = CacheTable.queryHistoryByKey(key: id) {
                    pinyinHistory = CacheTable.toArray(jsonString: cache.pinyinArray!)!.first as! String
                    words = CacheTable.toArray(jsonString: cache.wordArray!)! as! Array<String>
                    historyCount = words.count
                }
            }
            if id == "" {
                words.removeAll()
                pinyins.removeAll()
            } else {
                let tuples = idToStrings(id, startIndex: indexStore.last!)
                pinyins = tuples.0
                if pinyins.count > 0 {
                    // 根据拼音查找所有对应的文字
                    if let str = pinyinToWord[pinyins[currentIndex]] {
                        if isInHistory {
                            let tempArr = stringToArray(str)
                            var arr = [String]()
                            var flag = true
                            for temp in tempArr {
                                for word in words {
                                    if temp == word {
                                        flag = false
                                    }
                                }
                                if flag {
                                    arr.append(temp)
                                }
                                flag = true
                            }

                            words.append(contentsOf: arr)
                        } else {
                            words = stringToArray(str)
                            historyCount = 0
                        }
                        
                        // 将最有可能的文字，放到前面
                        if let tables = tuples.2 {
                            var possibleWords = tables.map { (table) -> String in
                                return table.words!
                            }
                            
                            // 如果历史缓存中有结果，则移除历史结果
                            if isInHistory {
                                // 将缓存中的内容提前显示
                                for i in (0..<historyCount).reversed() {
                                    let w = words[i]
                                    if possibleWords.contains(w) {
                                        let index = possibleWords.firstIndex(of: w)!
                                        possibleWords.remove(at: index)
                                    }
                                }
                            }
                            
                            if words.count > 0 {
                                words.insert(contentsOf: possibleWords, at: historyCount)
                            } else {
                                words = possibleWords
                            }
                            
                            // 设置为历史记录方式，当点击选中词时，将不再分词选择，而是直接将内容放到文本框中
                            pinyinHistory = PinyinStore.splitPinyinStrings(tuples.1)
                            isInHistory = true
                            historyCount += possibleWords.count
                        }
                    }
                } else {
                    words.removeAll()
                }
            }
        }
    }
    
    var currentIndex = 0 {                   //当前选拼音的位置
        didSet {
            if pinyins.count > 0 {
                if let str = pinyinToWord[pinyins[currentIndex]] {
                    isInHistory = false
                    words = stringToArray(str)
                    pinyinSelected = pinyins[currentIndex]
                }
            }
        }
    }
    var historyCount = 0
    var needSearchHistory = true
    var indexStore = [0]                    //记录
    var isInHistory: Bool = false           //历史记录中是否有
    var pinyins = [String]()                //当前字的拼音
    var pinyinHistory: String = ""          //历史记录中的分好词的拼音
    var pinyinSelected = ""                 //已经选中的拼音
    var allPinyins = [String]()             //所有选中的拼音
    var wordSelected = [String]()           //已选中的字
    
    var splitedPinyinString: String {       //分好词的结果
        get {
            if isInHistory {
                return pinyinHistory
            } else {
                return PinyinStore.splitPinyinStrings(idToStrings(id, startIndex: indexStore.last!).1)
            }
        }
    }
    
    var words: [String] = []
    
    func clearData() {
        isInHistory = false
        id = ""
        currentIndex = 0
        indexStore = [0]
        needSearchHistory = true
        pinyins = []
        pinyinHistory = ""
        pinyinSelected = ""
        wordSelected = []
        allPinyins = []
        historyCount = 0
    }
    
    func findIdInHistory(_ key: String) -> Bool {
        
        if CacheTable.queryHistoryByKey(key: key) != nil {
            return true
        }
        
        return false
//        if let dict = historyDictionary {
//
//            let value = dict.value(forKey: key) as? Array<[String]>
//            if value != nil {       //历史记录里有
//                return true
//            } else {
//                return false
//            }
//
//        } else {
//            return false
//        }
    }
    
    /*
     拼音组合
     [m, n, o],
     [x, y],
     [t]
     结果：["mxt", "myt", "nxt", "nyt", "oxt", "oyt"]
     */
    func pinYinCombination(results: [[String]]) -> [String]? {
        if results.count >= 2 {
            // 先取出第一个数组
            let firstArray = results.first!
            let len1 = firstArray.count
            // 再取出第二个数组
            let secondArray = results[1]
            let len2 = secondArray.count
            // 定义一个新数组
            var newArray = Array(repeating: "", count: len1 * len2)
            var index = 0
            
            for i in 0..<len1 {
                for j in 0..<len2 {
                    let newStr = firstArray[i] + "%" + secondArray[j]
                    if !newArray.contains(newStr) {
                        newArray[index] = newStr
                    }
                    index += 1
                }
            }
            
            // 过滤空元素
            newArray = newArray.compactMap { (str) -> String? in
                if str.count > 0 {
                    return str
                }
                return nil
            }
            
            // 使用递归
            var remainingArray = [[String]]()
            remainingArray.append(newArray)
            for m in 2..<results.count {
                remainingArray.append(results[m])
            }
            return pinYinCombination(results: remainingArray)
        } else {
            return results.first
        }
    }
    
    // 把拼音词组分割为字符串显示
    class func splitPinyinStrings(_ strings: [String]) -> String {
        var str = ""
        for pinyin in strings {
            if pinyin != strings.last {
                str += "\(pinyin)'"
            } else {
                str += pinyin
            }
        }
        return str
    }
    
    // 将九宫格组合，转为可能的拼音组合
    func idToStrings(_ typeId: String, startIndex: Int) -> ([String], [String], [CommonTable]?) {
        
        var firstStrings = [String]()
        var strings = [String]()
        
        var remainingLength = typeId.count
        var tempId = ""
        var index = startIndex
        remainingLength -= indexStore.last!

        // 限定为6是因为拼音中最长的就是6位
        for amount in (1...6).reversed() {
            if amount > remainingLength {
                continue
            }
            // id组合中，逐一找出最长的组合
            tempId = typeId[index...(index+amount)]
            // 根据组合查找对应的拼音
            if let tempStrings = idStringDict[tempId] {
                // 将可能的拼音组合放到数组中
                for tempString in tempStrings {
                    firstStrings.append(tempString)
                }
            }
        }
        
        for str in wordSelected {
            strings.append(str)
        }
        if pinyinSelected.count > 0 {
            strings.append(pinyinSelected)
        }
        
        // 有可能的组合
        var possibleArray = [[String]]()
        
        while remainingLength > 0 {
            for amount in (1...6).reversed() {
                if amount > remainingLength {
                    continue
                }
                tempId = typeId[index...(index+amount)]
                if let tempStrings = idStringDict[tempId] {
                    // 将九宫格数字组合结果存放在数组中
                    possibleArray.append(tempStrings)
                    for tempString in tempStrings {
                        strings.append(tempString)
                        break
                    }
                    index += amount
                    remainingLength -= amount
                    break
                }
            }
        }
        
        // 根据排列组合，查找数据库中权重最高的词语
        var leftStrings = firstStrings
        var rightStrings = strings
        var closerAnwsers: [CommonTable]?
        if pinyinSelected.count == 0 && wordSelected.count == 0 && typeId.count <= 7 {
            //将词语简写组合
            if possibleArray.count > 0, let combination = pinYinCombination(results: possibleArray) {
                // 将结果插入最前面
                if let tables = CommonTable.queryPinYin(pinyins: combination), tables.count > 0 {
                    closerAnwsers = tables
                    // 把第一个结果作为标准
                    let table = tables.first!
                    // firstStrings的优先级修改
                    let firstItem = leftStrings.first!
                    var moveIndex: Int?
                    if firstItem.count == 1 {
                        // 如果是简写
                        if let c = table.abbr?.first {
                            for index in 0..<leftStrings.count {
                                let item = leftStrings[index]
                                if item == String(c) {
                                    // 找到当前元素与最佳结果匹配
                                    moveIndex = index
                                    break
                                }
                            }
                        }
                    } else {
                        // 如果是全拼
                        if let pinyins = table.pinyin?.split(separator: "'"), pinyins.count > 0 {
                            for index in 0..<leftStrings.count {
                                let item = leftStrings[index]
                                if item == pinyins.first! {
                                    // 找到当前元素与最佳结果匹配
                                    moveIndex = index
                                    break
                                }
                            }
                        }

                    }

                    // 将最佳元素置顶
                    if let index = moveIndex {
                        let topItem = leftStrings[index]
                        leftStrings.remove(at: index)
                        leftStrings.insert(topItem, at: 0)
                    }

                    //strings的优先级修改
                    for i in 0..<strings.count {
                        let item = strings[i]
                        if i == 0 {
                            rightStrings[i] = leftStrings[i]
                        } else {
                            if item.count == 1 {
                                // 简写
                                if let abbr = table.abbr, abbr.count > i {
                                    let startIndex = abbr.index(abbr.startIndex, offsetBy: i)
                                    let endIndex = abbr.index(abbr.startIndex, offsetBy: i + 1)
                                    rightStrings[i] = String(abbr[startIndex..<endIndex])
                                }
                            } else {
                                //拼音
                                if let pinyins = table.pinyin?.split(separator: "'"), pinyins.count > i {
                                    let pinyin = pinyins[i]
                                    let startIndex = pinyin.index(pinyin.startIndex, offsetBy: 0)
                                    let endIndex = pinyin.index(pinyin.startIndex, offsetBy: item.count)
                                    rightStrings[i] = String(pinyin[startIndex..<endIndex])
                                }
                            }
                        }
                    }

                    firstStrings = leftStrings
                    strings = rightStrings
                }
            }
        }
        
        print("possibleArray = \(possibleArray)")
        print("firstStrings = \(firstStrings), strings = \(strings)")
        return (firstStrings, strings, closerAnwsers)
    }    
}


func stringToArray(_ str: String) -> [String] {
    
    var strings = [String]()
    
    for temp in str {
        strings.append(String(temp))
    }

    return strings
}



















