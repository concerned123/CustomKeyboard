//
//  ViewController.swift
//  MYKeyboard
//
//  Created by MiY on 2017/3/19.
//  Copyright © 2017年 MiY. All rights reserved.
//

import UIKit
import SnapKit

class ViewController: UIViewController/*, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout*/ {

    let textView = UITextView()
    
    var collectionView: UICollectionView!


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        textView.backgroundColor = UIColor.groupTableViewBackground
        self.view.addSubview(textView)
        textView.snp.makeConstraints({ (make) -> Void in
            make.left.equalTo(30)
            make.right.equalTo(-30)
            make.top.equalTo(50)
            make.height.equalTo(200)
        })
        
//        print(pinYinAlgorithm(results: [["m", "n", "o"], ["x", "y"], ["t"]]))
    }

    
    func pinYinAlgorithm(results: [[String]]) -> [String]? {
        if results.count == 0 {
            return nil
        }
        
        // 结果数组，第一次先添加一个空字符串
        var possibleArray = [String]()
        possibleArray.append("")
        
        for i in 0..<results.count {
            // 取出当前数组
            let array = results[i]
            let size = possibleArray.count
            for _ in 0..<size {
                // 每次都从队列中拿出第一个元素
                let firstItem = possibleArray.removeFirst()
                
                // 然后跟"def"这样的字符串拼接，并再次放到队列中
                for k in 0..<array.count {
                    possibleArray.append(firstItem + array[k])
                }
            }
        }
        
        return possibleArray
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

class MyConllectionViewCell: UICollectionViewCell {
    
    var blueView: UIView
    
    override init(frame: CGRect) {
        
        blueView = UIView()
        blueView.backgroundColor = UIColor.blue
        super.init(frame: frame)
        
        self.addSubview(blueView)
        blueView.snp.makeConstraints({ (make) -> Void in
            make.edges.equalToSuperview()
        })

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

