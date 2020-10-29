//
//  KeyView.swift
//  MYKeyboard
//
//  Created by MiY on 2017/3/22.
//  Copyright © 2017年 MiY. All rights reserved.
//

import UIKit

let grayColor = UIColor(red: 184.0/255.0, green: 188.0/255.0, blue: 196.0/255.0, alpha: 1)
let blueColor = UIColor.init(red: 10/255.0, green: 96/255.0, blue: 254/255.0, alpha: 1)

class KeyView: UIControl {
    
    let titleLabel = UILabel()
    let iconImageView = UIImageView()
    let key: Key
    
    init(withKey key: Key) {
        self.key = key

        super.init(frame: CGRect.zero)
        updateBackgroundColorWithType(key.type)

        titleLabel.text = key.title
        titleLabel.sizeToFit()
        titleLabel.textAlignment = .center
        self.addSubview(titleLabel)
        
        // 设置按钮文字颜色
        if key.type == .reType {
            titleLabel.textColor = optionColor
        }
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        
        titleLabel.snp.makeConstraints({ (make) -> Void in
            make.center.equalToSuperview()
        })

        super.layoutSubviews()
        
        // 新增类型
        if key.type == .capital {
            backgroundColor = grayColor
            if key.capitalType == .lowercaseType {
                iconImageView.image = UIImage(named: "capital_select")
            } else if key.capitalType == .uppercaseType {
                iconImageView.image = UIImage(named: "capital")
                backgroundColor = UIColor.white
            }
            addSubview(iconImageView)
            iconImageView.snp.makeConstraints { (make) in
                make.center.equalToSuperview()
                make.size.equalTo(CGSize(width: 19, height: 17))
            }
        } else if key.type == .backspace {
            iconImageView.image = UIImage(named: "delete_button")
            addSubview(iconImageView)
            iconImageView.snp.makeConstraints { (make) in
                make.center.equalToSuperview()
                make.size.equalTo(CGSize(width: 23, height: 17))
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        // 大小写类型按键不显示
        if key.type == .capital {
            return
        }
        
        let color = self.backgroundColor
        if color == UIColor.white {
            self.backgroundColor = grayColor
        } else {
            self.backgroundColor = UIColor.white
            if self.key.type == .return {
                self.titleLabel.textColor = UIColor.black
            }
        }
        
        if key.type == .normal {
            // 九宫格按键，按下时变灰
            backgroundColor = grayColor
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        updateBackgroundColorWithType(key.type)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        updateBackgroundColorWithType(key.type)
    }

    /// 设置按键颜色
    func updateBackgroundColorWithType(_ type: KeyType) {
        switch type {
        case .symbol,
             .backspace,
             .nextKeyboard,
             .pinyin,
             .reType,
             // 新增类型
             .numberSwitch,
             .chSwitch,
             .numberToLetter,
             .symbolSwitch:
            backgroundColor = grayColor
        case .return:
            backgroundColor = blueColor
            titleLabel.textColor = UIColor.white
        default:
            backgroundColor = UIColor.white
        }
        
        if type == .capital {
            if key.capitalType == .lowercaseType {
                iconImageView.image = UIImage(named: "capital_select")
                backgroundColor = grayColor
            } else if key.capitalType == .uppercaseType {
                iconImageView.image = UIImage(named: "capital")
                backgroundColor = UIColor.white
            } else if key.capitalType == .alwaysUppercaseType {
                iconImageView.image = UIImage(named: "capital_lock")
                backgroundColor = UIColor.white
            }
        }
    }
}





