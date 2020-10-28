//
//  CommonTable.swift
//  MiYKeyboard
//
//  Created by xuyang on 2020/10/21.
//  Copyright © 2020 MiY. All rights reserved.
//

import Foundation
import FMDB

struct CommonTable: Codable {
    
    var id: Int?
    
    var pinyin: String?
    
    var words: String?
    
    var frequency: Int?
    
    var abbr: String?
    
    /// 设置行名
    private enum Columns: String {
        ///
        case id = "id"
        ///
        case pinyin = "pinyin"
        ///
        case words = "words"
        ///
        case frequency = "frequency"
        ///
        case abbr = "abbr"
    }
}

extension CommonTable {
    
    /// 获取数据库对象
    private static let dataBase: FMDatabase = DBManager.dbQueue
    
    /// 启动环境
    static func start() {
        // 将本地db文件拷贝到沙盒中
        if !FileManager.default.fileExists(atPath: DBManager.dbPath) {
            let proPath = Bundle.main.path(forResource: "commonWords", ofType: "db")!
            do {
                try FileManager.default.copyItem(atPath: proPath, toPath: DBManager.dbPath)
                debugPrint("文件移动成功")
            } catch {
                debugPrint("文件移动失败")
            }
        }
        
        // 准备数据
        if !tableIsExist(name: TableName.common) {
            prepareData()
        }
        
        if !tableIsExist(name: TableName.cache) {
            CacheTable.createTable()
        }
    }
    
    /// 将词库文件中的内容写入到数据库
    static func prepareData() {
        debugPrint("准备数据")
        if let path = Bundle.main.path(forResource: "commonWords", ofType: "txt") {
            do {
                let data = try String(contentsOfFile: path, encoding: .utf16)
                var fileLineArray = data.components(separatedBy: .newlines)
                fileLineArray.removeAll { (content) -> Bool in
                    return content.count == 0
                }

                //["a", "啊", "614"]
//                let column = fileLineArray.first!.components(separatedBy: " ")
//                print(column)

                // 创建数据库
                var commons = [CommonTable]()
                for content in fileLineArray {
                    let column = content.components(separatedBy: " ")
                    var com = CommonTable()
                    com.pinyin = column[0]
                    com.words = column[1]
                    com.frequency = Int(column[2])

                    // 简写   a'a
                    let pinyin = column[0]
                    let pinyinCombination = pinyin.components(separatedBy: "'")
                    var abbr = ""
                    for pinyin in pinyinCombination {
                        abbr += String(pinyin.first!)
                    }
                    com.abbr = abbr
                    commons.append(com)
                }

                CommonTable.insertArray(commons: commons)
            } catch {
                debugPrint(error)
            }
        }
    }
    
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
    private static func createTable() {
        let sql =
            """
            create table if not exists \(TableName.common)
            (
                \(CommonTable.Columns.id.rawValue) integer Primary Key Autoincrement,
                \(CommonTable.Columns.pinyin.rawValue) text,
                \(CommonTable.Columns.words.rawValue) text,
                \(CommonTable.Columns.frequency.rawValue) integer,
                \(CommonTable.Columns.abbr.rawValue) text
            )
            """
        do {
            try dataBase.executeUpdate(sql, values: nil)
            debugPrint("表创建成功")
        } catch {
            debugPrint(error)
        }
    }
    
    /// 批量插入
    static func insertArray(commons: [CommonTable]) {
        // 创建表
        if !tableIsExist(name: TableName.common) {
            createTable()
        }
        // 开启事务
        dataBase.beginTransaction()
        
        do {
            for com in commons {
                let sql =
                    """
                    insert into \(TableName.common)
                    (
                        \(CommonTable.Columns.pinyin.rawValue),
                        \(CommonTable.Columns.words.rawValue),
                        \(CommonTable.Columns.frequency.rawValue),
                        \(CommonTable.Columns.abbr.rawValue)
                    ) values(?,?,?,?)
                    """
                
                try dataBase.executeUpdate(sql, values: [com.pinyin!, com.words!, com.frequency!, com.abbr!])
            }
            
            // 事务提交
            dataBase.commit()
            debugPrint("数据插入成功")
        } catch {
            // 事务回滚
            dataBase.rollback()
            debugPrint("数据插入失败，已回滚")
        }
    }
    
    /// 通过简写查询内容
    static func queryAbbr(abbrs: [String]) -> [CommonTable]? {
        // 拼条件
        var condition = ""
        for abbr in abbrs {
            if abbr == abbrs.last {
                condition += "'\(abbr)'"
            } else {
                condition += "'\(abbr)',"
            }
        }
        
        let sql = """
            SELECT
            \(CommonTable.Columns.pinyin.rawValue),
            \(CommonTable.Columns.words.rawValue),
            \(CommonTable.Columns.abbr.rawValue)
            FROM \(TableName.common)
            WHERE \(CommonTable.Columns.abbr.rawValue) in (\(condition))
            ORDER by \(CommonTable.Columns.frequency.rawValue) DESC
            """
        
        do {
            let rs = try dataBase.executeQuery(sql, values: nil)
            var results = [CommonTable]()
            while rs.next() {
                var result = CommonTable()
                result.pinyin = rs.string(forColumn: CommonTable.Columns.pinyin.rawValue)
                result.words = rs.string(forColumn: CommonTable.Columns.words.rawValue)
                result.abbr = rs.string(forColumn: CommonTable.Columns.abbr.rawValue)
                results.append(result)
            }
            return results
        } catch {
            debugPrint("数据查询失败")
            return nil
        }
    }
    
    // 查找联想词
    static func queryAssociateWords(text: String) -> [String]? {
        let sql = """
        SELECT \(CommonTable.Columns.words.rawValue)
        FROM \(TableName.common)
        WHERE \(CommonTable.Columns.words.rawValue) LIKE '\(text)%'
        ORDER by \(CommonTable.Columns.frequency.rawValue) DESC
        LIMIT 0, 20
        """
        
        do {
            let rs = try dataBase.executeQuery(sql, values: nil)
            var results = [String]()
            while rs.next() {
                if let words = rs.string(forColumn: CommonTable.Columns.words.rawValue) {
                    let ret = words.suffix(words.count - text.count)
                    if ret.count > 0 {
                        results.append(String(ret))
                    }
                }
            }
            return results
        } catch {
            debugPrint("数据查询失败")
            return nil
        }
    }
    
    // 查询拼音
    static func queryPinYin(pinyins: [String]) -> [CommonTable]? {
        var condition = ""
        for i in 0..<pinyins.count {
            let pinyin = pinyins[i]
            if i == 0 {
                condition += "\(CommonTable.Columns.pinyin.rawValue) LIKE '\(pinyin)%'"
            } else {
                condition += " OR \(CommonTable.Columns.pinyin.rawValue) LIKE '\(pinyin)%'"
            }
        }
        
        let sql = """
            SELECT
            \(CommonTable.Columns.pinyin.rawValue),
            \(CommonTable.Columns.abbr.rawValue),
            \(CommonTable.Columns.words.rawValue)
            FROM \(TableName.common)
            WHERE \(condition)
            ORDER by \(CommonTable.Columns.frequency.rawValue) DESC
            LIMIT 0, 5
            """
        
//        debugPrint("拼音查询sql = \(sql)")
        do {
            let rs = try dataBase.executeQuery(sql, values: nil)
            var results = [CommonTable]()
            while rs.next() {
                var result = CommonTable()
                result.pinyin = rs.string(forColumn: CommonTable.Columns.pinyin.rawValue)
                result.abbr = rs.string(forColumn: CommonTable.Columns.abbr.rawValue)
                result.words = rs.string(forColumn: CommonTable.Columns.words.rawValue)
                results.append(result)
            }
            return results
        } catch {
            debugPrint("数据查询失败")
            return nil
        }
    }
    
}


