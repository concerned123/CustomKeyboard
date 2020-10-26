//
//  GlobalExtension.swift
//  MiYKeyboard
//
//  Created by xuyang on 2020/10/23.
//  Copyright © 2020 MiY. All rights reserved.
//

import Foundation
import UIKit

//扩展UICollectionView 使得滑动scrollView可以取消UIControl的点击事件
extension UICollectionView {
    override open func touchesShouldCancel(in view: UIView) -> Bool {
        return true
    }
}

extension String {
    subscript (bounds: CountableClosedRange<Int>) -> String {
        get {
            let startIndex = self.index(self.startIndex, offsetBy: bounds.lowerBound)
            let endIndex = self.index(self.startIndex, offsetBy: bounds.upperBound)
//            let range: Range<String.Index> = Range(uncheckedBounds: (startIndex, endIndex))
            
//            return self[range]
            return String(self[startIndex..<endIndex])
        }
    }
    
    subscript (bounds: CountableRange<Int>) -> String {
        get {
            let startIndex = self.index(self.startIndex, offsetBy: bounds.lowerBound)
            let endIndex = self.index(self.startIndex, offsetBy: bounds.upperBound - 1)
//            let range: Range<String.Index> = Range(uncheckedBounds: (startIndex, endIndex))
            
//            return self[range]
            return String(self[startIndex..<endIndex])
        }
    }
}
