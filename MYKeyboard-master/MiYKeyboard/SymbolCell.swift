//
//  SymbolCell.swift
//  MYKeyboard
//
//  Created by MiY on 2017/3/24.
//  Copyright © 2017年 MiY. All rights reserved.
//

import UIKit

class SymbolCell: UICollectionViewCell {
    
    var keyView: KeyView?
    let line = UIView()
    var index: Int?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    func addPinyin(_ pinyin: String, index: Int) {
        let key = Key(withTitle: pinyin, andType: .pinyin)
        key.index = index
        addKey(key)
    }
    
    func addKey(_ key: Key) {        
        keyView = KeyView(withKey: key)
        line.backgroundColor = lineColor
        
        self.contentView.addSubview(keyView!)
        self.contentView.addSubview(line)
        
        keyView?.snp.makeConstraints({ (make) -> Void in
            make.edges.equalToSuperview()
        })
        line.snp.makeConstraints({ (make) -> Void in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(lineThickness)
        })
    }

    override func layoutSubviews() {

        super.layoutSubviews()
        
    }

    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
