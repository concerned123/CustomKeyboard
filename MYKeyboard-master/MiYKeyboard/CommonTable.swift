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
    
    /// 将词库文件中的内容写入到数据库
    static func prepareData() {
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
//                    CommonTable.insert(common: com)
                    commons.append(com)
                }

                CommonTable.insertArray(commons: commons)

            } catch {
                print(error)
            }
        }
    }
    
    /// 创建表
    private static func createTable() {
        let sql = "create table if not exists common_table (id integer Primary Key Autoincrement, pinyin text, words text, frequency integer, abbr text)"
        do {
            try dataBase.executeUpdate(sql, values: nil)
            print("表创建成功")
        } catch {
            print(error)
        }
    }
    
    /// 批量插入
    static func insertArray(commons: [CommonTable]) {
        // 创建表
        createTable()
        // 开启事务
        dataBase.beginTransaction()
        
        do {
            for com in commons {
                let sql = "insert into \(TableName.common)(\(CommonTable.Columns.pinyin.rawValue), \(CommonTable.Columns.words.rawValue), \(CommonTable.Columns.frequency.rawValue), \(CommonTable.Columns.abbr.rawValue)) values(?,?,?,?)"
                
                try dataBase.executeUpdate(sql, values: [com.pinyin!, com.words!, com.frequency!, com.abbr!])
            }
            
            // 事务提交
            dataBase.commit()
            print("数据插入成功")
        } catch {
            // 事务回滚
            dataBase.rollback()
            print("数据插入失败，已回滚")
        }
    }
    
    /// 查询
    
    
}


