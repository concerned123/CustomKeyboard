//
//  WordsCell.swift
//  MYKeyboard
//
//  Created by MiY on 2017/3/29.
//  Copyright © 2017年 MiY. All rights reserved.
//

import UIKit

class WordsCell: UICollectionViewCell {
    
    var wordslabel = UILabel()
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
//        self.backgroundColor = UIColor.brown
//        self.contentView.backgroundColor = UIColor.red
        wordslabel.textAlignment = .center
        wordslabel.sizeToFit()
        wordslabel.font = UIFont.preferredFont(forTextStyle: .title3)
        wordslabel.textColor = UIColor.black

        self.contentView.addSubview(wordslabel)
        self.contentView.snp.makeConstraints({ (make) -> Void in
            make.top.left.bottom.equalToSuperview()
            make.right.equalTo(wordslabel)
        })
        
        wordslabel.snp.makeConstraints({ (make) -> Void in
            make.center.equalToSuperview()
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}










