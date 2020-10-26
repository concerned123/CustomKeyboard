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
}


class DBManager: NSObject {
    /// 数据库路径
    private static var dbPath: String = {
        // 获取工程内容数据库名字
        return Bundle.main.path(forResource: "commonWords", ofType: "db")!
    }()
    
    /// 数据库 用于多线程事务处理
    static var dbQueue: FMDatabase = {
        print(DBManager.dbPath)
        let db = FMDatabase(path: DBManager.dbPath)
        if db.open() {
            print("数据打开成功")
        } else {
            print("数据打开失败")
        }
        return db
    }()
}
