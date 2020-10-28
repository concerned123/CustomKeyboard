//
//  CacheTable.swift
//  MiYKeyboard
//
//  Created by xuyang on 2020/10/28.
//  Copyright © 2020 MiY. All rights reserved.
//

import Foundation
import FMDB

struct CacheTable: Codable {
    
    var id: Int?
    
    var keys: String?
    
    var pinyinArray: String?
    
    var wordArray: String?
    
    var frequencyArray: String?
    
    /// 设置行名
    private enum Columns: String {
        ///
        case id = "id"
        ///
        case keys = "keys"
        
        case pinyinArray = "pinyinArray"
        
        case wordArray = "wordArray"
        
        case frequencyArray = "frequencyArray"
    }
}

extension CacheTable {
    
    /// 获取数据库对象
    private static let dataBase: FMDatabase = DBManager.dbQueue
    
    /// 根据表名，查询表是否已经创建
    static func tableIsExist(name: String) -> Bool {
        let typeName = "name"
        let sql =
            """
            SELECT \(typeName) FROM sqlite_master WHERE type = "table"
            """
        
        do {
            let rs = try dataBase.executeQuery(sql, values: nil)
            while rs.next() {
                let tableName = rs.string(forColumn: typeName)
                if tableName == name {
                    return true
                }
            }
        } catch {
            debugPrint("数据查询失败")
        }
        
        return false
    }
    
    /// 创建表
    static func createTable() {
        let sql =
            """
            create table if not exists \(TableName.cache)
            (
                \(CacheTable.Columns.id.rawValue) integer Primary Key Autoincrement,
                \(CacheTable.Columns.keys.rawValue) text,
                \(CacheTable.Columns.pinyinArray.rawValue) text,
                \(CacheTable.Columns.wordArray.rawValue) integer,
                \(CacheTable.Columns.frequencyArray.rawValue) text
            )
            """
        do {
            try dataBase.executeUpdate(sql, values: nil)
            debugPrint("表创建成功")
        } catch {
            debugPrint(error)
        }
    }
    
    /// 插入一条记录
    static func insertCache(table: CacheTable) {
        let sql =
        """
        insert into \(TableName.cache)
        (
            \(CacheTable.Columns.keys.rawValue),
            \(CacheTable.Columns.pinyinArray.rawValue),
            \(CacheTable.Columns.wordArray.rawValue),
            \(CacheTable.Columns.frequencyArray.rawValue)
        ) values(?,?,?,?)
        """
        
        // 开启事务
        dataBase.beginTransaction()
        
        do {
            try dataBase.executeUpdate(sql, values: [table.keys!, table.pinyinArray!, table.wordArray!, table.frequencyArray!])
            // 事务提交
            dataBase.commit()
            debugPrint("已缓存一条记录")
        } catch {
            // 事务回滚
            dataBase.rollback()
            debugPrint("缓存记录失败，已回滚")
        }
    }
    
    /// 通过key查询记录
    static func queryHistoryByKey(key: String) -> CacheTable? {
        let sql =
        """
        SELECT * from \(TableName.cache)
        WHERE \(CacheTable.Columns.keys.rawValue) = "\(key)"
        """
        
        do {
            let rs = try dataBase.executeQuery(sql, values: nil)
            if rs.next() {
                var table = CacheTable()
                table.id = Int(rs.int(forColumn: CacheTable.Columns.id.rawValue))
                table.keys = rs.string(forColumn: CacheTable.Columns.keys.rawValue)
                table.pinyinArray = rs.string(forColumn: CacheTable.Columns.pinyinArray.rawValue)
                table.wordArray = rs.string(forColumn: CacheTable.Columns.wordArray.rawValue)
                table.frequencyArray = rs.string(forColumn: CacheTable.Columns.frequencyArray.rawValue)
                return table
            }
        } catch {
            debugPrint("数据查询失败")
        }
        
        return nil
    }
    
    /// 更新缓存
    static func update(table: CacheTable) {
        let sql =
        """
        UPDATE \(TableName.cache)
        SET
        \(CacheTable.Columns.pinyinArray.rawValue) = ?,
        \(CacheTable.Columns.wordArray.rawValue) = ?,
        \(CacheTable.Columns.frequencyArray.rawValue) = ?
        WHERE \(CacheTable.Columns.id.rawValue) = "\(table.id!)"
        """
        
        // 开启事务
        dataBase.beginTransaction()
        
        do {
            try dataBase.executeUpdate(sql, values: [table.pinyinArray!, table.wordArray!, table.frequencyArray!])
            // 事务提交
            dataBase.commit()
            debugPrint("更新缓存成功")
        } catch {
            // 事务回滚
            dataBase.rollback()
            debugPrint("更新缓存记录失败，已回滚")
        }
    }
    
    /// 缓存一条记录
    static func cache(key: String, pinyin: String, word: String) {

        debugPrint("保存 key = \(key), pinyin = \(pinyin), word = \(word)")
        
        if let cache = queryHistoryByKey(key: key) {
            var table = cache
            
            if let pinyins = toArray(jsonString: table.pinyinArray!), let words = toArray(jsonString: table.wordArray!), let frequencys = toArray(jsonString: table.frequencyArray!) {
                
                // 如果在记录中，找到了拼音一样，汉字一样的记录，则将权重 + 1
                var isSame = false
                for i in 0..<pinyins.count {
                    if pinyins[i] as! String == pinyin && words[i] as! String == word {
                        let count = frequencys[i] as! Int
                        var newFrequencys = frequencys
                        newFrequencys[i] = count + 1
                        isSame = true
                        table.frequencyArray = toJson(array: newFrequencys)
                    }
                }
                
                // 如果没有找到相同记录，则将当前记录插入缓存
                if !isSame {
                    var newPinyins = pinyins
                    var newWords = words
                    var newFrequencys = frequencys
                    
                    newPinyins.insert(pinyin, at: 0)
                    newWords.insert(word, at: 0)
                    newFrequencys.insert(1, at: 0)
                    
                    table.pinyinArray = toJson(array: newPinyins)
                    table.wordArray = toJson(array: newWords)
                    table.frequencyArray = toJson(array: newFrequencys)
                } else {
                    // 更新频率之后，进行频率排序
                    // 根据使用频率排序
                    let pinyins = CacheTable.toArray(jsonString: table.pinyinArray!)!
                    let words = CacheTable.toArray(jsonString: table.wordArray!)!
                    let frequencys = CacheTable.toArray(jsonString: table.frequencyArray!)!
                    
                    var sortNewPinyins = pinyins
                    sortNewPinyins.sort { (a, b) -> Bool in
                        let indexA = pinyins.firstIndex { (item) -> Bool in
                            return (item as! String) == (a as! String)
                        }
                        
                        let indexB = pinyins.firstIndex { (item) -> Bool in
                            return (item as! String) == (b as! String)
                        }
                        
                        let freA = frequencys[indexA!] as! Int
                        let freB = frequencys[indexB!] as! Int
                        return freA > freB
                    }
                    
                    var sortNewWords = words
                    sortNewWords.sort { (a, b) -> Bool in
                        let indexA = words.firstIndex { (item) -> Bool in
                            return (item as! String) == (a as! String)
                        }
                        
                        let indexB = words.firstIndex { (item) -> Bool in
                            return (item as! String) == (b as! String)
                        }
                        
                        let freA = frequencys[indexA!] as! Int
                        let freB = frequencys[indexB!] as! Int
                        return freA > freB
                    }
                    
                    var sortNewFrequency = frequencys
                    sortNewFrequency.sort { (a, b) -> Bool in
                        return (a as! Int) > (b as! Int)
                    }
                    
                    table.pinyinArray = CacheTable.toJson(array: sortNewPinyins)
                    table.wordArray = CacheTable.toJson(array: sortNewWords)
                    table.frequencyArray = CacheTable.toJson(array: sortNewFrequency)
                }
                
                // 更新记录
                update(table: table)
            }
        } else {
            // 不存在记录，则插入缓存记录
            var table = CacheTable()
            table.keys = key
            table.pinyinArray = toJson(array: [pinyin])
            table.wordArray = toJson(array: [word])
            table.frequencyArray = toJson(array: [1])
            
            if table.pinyinArray != nil, table.wordArray != nil, table.frequencyArray != nil {
                insertCache(table: table)
            }
        }
    }
    
    /// 数组转为json
    static func toJson(array: Array<Any>) -> String? {
        if (!JSONSerialization.isValidJSONObject(array)) {
            debugPrint("无法解析出JSONString")
            return nil
        }
             
        let data: NSData! = try? JSONSerialization.data(withJSONObject: array, options: []) as NSData?
        let JSONString = NSString(data:data as Data,encoding: String.Encoding.utf8.rawValue)
        return JSONString! as String
    }
    
    /// json转为数组
    static func toArray(jsonString: String) -> Array<Any>? {
        let jsonData:Data = jsonString.data(using: .utf8)!
         
        let array = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
        if array != nil {
            return array as? Array
        }
        
        return nil
    }
    
}
