//
//  DataManager.swift
//  MiYKeyboard
//
//  Created by xuyang on 2020/10/21.
//  Copyright © 2020 MiY. All rights reserved.
//

import Foundation
import FMDB

/// 数据库名字
struct DataBaseName {
    static let dbName = "commonWords.db"
}

/// 数据库表名
struct TableName {
    static let common = "common_table"
    static let cache = "cache_table"
}


class DBManager: NSObject {
    /// 数据库路径
    static var dbPath: String = {
        // 获取工程内容数据库名字
        //Bundle.main.path(forResource: "commonWords", ofType: "db")!
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        let documentsDirectory = paths.object(at: 0) as! NSString
        return documentsDirectory.appendingPathComponent(DataBaseName.dbName)
    }()
    
    /// 数据库 用于多线程事务处理
    static var dbQueue: FMDatabase = {
        let db = FMDatabase(path: DBManager.dbPath)
        debugPrint("数据库位置 = \(DBManager.dbPath)")
        if db.open() {
            debugPrint("数据打开成功")
        } else {
            debugPrint("数据打开失败")
        }
        return db
    }()
}
