//
//  PinYinKeyboardView.swift
//  MiYKeyboard
//
//  Created by xuyang on 2020/10/22.
//  Copyright © 2020 MiY. All rights reserved.
//

import UIKit

let bannerHeight = 60 as CGFloat
let bannerLineColor = UIColor(red: 226.0/255.0, green: 226.0/255.0, blue: 226.0/255.0, alpha: 1)
let lineColor = UIColor.lightGray
let lineThickness = 0.5

let leftSymbolWidth: CGFloat = 65

let historyPath: String = { () -> String in
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
    let documentsDirectory = paths.object(at: 0) as! NSString
    let path = documentsDirectory.appendingPathComponent("TypingHistory.plist")
    
    debugPrint("历史记录保存位置 \(path)")
    return path
}()

var historyDictionary: NSMutableDictionary? {
    get {
        return NSMutableDictionary(contentsOfFile: historyPath)
    }
}

class PinYinKeyboardView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var bannerView: UIView = UIView()                           // 顶部候选词视图
    var bottomView: UIView = UIView()                           // bannerView下面的键盘视图
    var pinyinLabel: UILabel = UILabel()                        // 顶部输入拼音显示label
    var letterKeyboardView = LetterKeyboardView()               // 字母键盘
    var wordsQuickCollection: UICollectionView!                 // 候选词滑动视图
    var symbolCollection: UICollectionView!                     // 左侧拼音选项视图
    var numberView = UIView()                                   // 数字键盘
    let closeButton = UIButton()
    
    weak var delegate: KeyboardViewController!
    var keysDictionary = [String: KeyView]()
    
    var symbolStore = SymbolKeyStore()
    var pinyinStore = PinyinStore()
    
    var selectedIndex = 0                                                   // 选拼音index
    var saveIndex = true                                                    // true为没有选中拼音，false为已经选中拼音
    var isTyping = false                                                    // 打字模式
    var isClickSpaceOrWord = false                                          // 是否点击了空格或者选择了字
    var idString: String = ""                                               // 当前的九宫格按键组合
    
    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        prepareSubview()
        addViewsToBanner()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - 视图布局
    func prepareSubview() {
        // 顶部选词视图
        addSubview(bannerView)
        bannerView.backgroundColor = UIColor.white
        bannerView.snp.makeConstraints({ (make) -> Void in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(bannerHeight)
        })
        
        // 键盘布局视图
        addSubview(bottomView)
        bottomView.snp.makeConstraints({ (make) -> Void in
            make.top.equalTo(bannerView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        })
        
        // MARK: 左 Collection View
        let layout = UICollectionViewFlowLayout.init()
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.itemSize = CGSize(width: leftSymbolWidth, height: 40.5)
        
        symbolCollection = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        symbolCollection.delaysContentTouches = false
        symbolCollection.canCancelContentTouches = true
        symbolCollection.backgroundColor = grayColor
        symbolCollection.delegate = self
        symbolCollection.dataSource = self
        symbolCollection.register(SymbolCell.self, forCellWithReuseIdentifier: "SymbolCell")
        
        bottomView.addSubview(symbolCollection)
        symbolCollection.snp.makeConstraints({ (make) -> Void in
            make.top.left.equalToSuperview()
//            make.width.equalToSuperview().dividedBy(5)
            make.width.equalTo(leftSymbolWidth)
            make.height.equalToSuperview().multipliedBy(0.75)
        })
        
        // MARK: 左下  切换输入法按钮
        let leftBottonView = UIView()
        bottomView.addSubview(leftBottonView)
        leftBottonView.snp.makeConstraints({ (make) -> Void in
            make.left.bottom.equalToSuperview()
            make.top.equalTo(symbolCollection.snp.bottom)
            make.width.equalTo(symbolCollection)
        })
        let viewLB = KeyView(withKey: Key(withTitle: "变", andType: .nextKeyboard))
        viewLB.addTarget(delegate, action: NSSelectorFromString("handleInputModeListFromView:withEvent:"), for: .allTouchEvents)
        leftBottonView.addSubview(viewLB)
        viewLB.snp.makeConstraints({ (make) -> Void in
            make.edges.equalToSuperview()
        })
        
        // MARK: 右
        let rightView = UIView()
        bottomView.addSubview(rightView)
        rightView.snp.makeConstraints({ (make) -> Void in
            make.width.equalTo(symbolCollection)
            make.top.right.bottom.equalToSuperview()
        })
        
        let viewR1 = KeyView(withKey: Key(withTitle: "", andType: .backspace))        //"⬅︎"
        let viewR2 = KeyView(withKey: Key(withTitle: "重输", andType: .reType))
        let viewR3 = KeyView(withKey: Key(withTitle: "发送", andType: .return))
        rightView.addSubview(viewR1)
        rightView.addSubview(viewR2)
        rightView.addSubview(viewR3)
        viewR1.snp.makeConstraints({ (make) -> Void in
            make.top.left.right.equalToSuperview()
            make.height.equalToSuperview().dividedBy(4)
        })
        viewR2.snp.makeConstraints({ (make) -> Void in
            make.top.equalTo(viewR1.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalToSuperview().dividedBy(4)
        })
        viewR3.snp.makeConstraints({ (make) -> Void in
            make.top.equalTo(viewR2.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        })
        
        
        // MARK: 中
        let centerView = UIView()
        bottomView.addSubview(centerView)
        centerView.snp.makeConstraints({ (make) -> Void in
            make.top.bottom.equalToSuperview()
            make.left.equalTo(symbolCollection.snp.right)
            make.right.equalTo(rightView.snp.left)
        })
        
        // MARK: 字母
        let view11 = KeyView(withKey: Key(withTitle: "符号", andType: .changeToSymbol, typeId: "1"))  //1
        let view12 = KeyView(withKey: Key(withTitle: "ABC", andType: .normal, typeId: "2"))          //2
        let view13 = KeyView(withKey: Key(withTitle: "DEF", andType: .normal, typeId: "3"))          //3
        let view21 = KeyView(withKey: Key(withTitle: "GHI", andType: .normal, typeId: "4"))          //4
        let view22 = KeyView(withKey: Key(withTitle: "JKL", andType: .normal, typeId: "5"))          //5
        let view23 = KeyView(withKey: Key(withTitle: "MNO", andType: .normal, typeId: "6"))          //6
        let view31 = KeyView(withKey: Key(withTitle: "PQRS", andType: .normal, typeId: "7"))         //7
        let view32 = KeyView(withKey: Key(withTitle: "TUV", andType: .normal, typeId: "8"))          //8
        let view33 = KeyView(withKey: Key(withTitle: "WXYZ", andType: .normal, typeId: "9"))         //9
        let view41 = KeyView(withKey: Key(withTitle: "123", andType: .changeToNumber))
        let view42 = KeyView(withKey: Key(withTitle: "空格", andType: .space, typeId: "0"))           //0
        let view43 = KeyView(withKey: Key(withTitle: "英文", andType: .changeToLetter, typeId: nil))
        let arrMid = [view11, view12, view13, view21, view22, view23, view31, view32, view33, view41, view42, view43]
        for view in arrMid {
            centerView.addSubview(view)
        }
        
        keysDictionary["删除"] = viewR1
        keysDictionary["换行"] = viewR2
        keysDictionary["发送"] = viewR3
        keysDictionary["1"] = view11
        keysDictionary["2"] = view12
        keysDictionary["3"] = view13
        keysDictionary["4"] = view21
        keysDictionary["5"] = view22
        keysDictionary["6"] = view23
        keysDictionary["7"] = view31
        keysDictionary["8"] = view32
        keysDictionary["9"] = view33
        keysDictionary["0"] = view42
        keysDictionary["123"] = view41
        keysDictionary["en"] = view43
        
        addConstraintsToMid(centerView, arrMid)
        centerView.addSubview(numberView)
        numberView.snp.makeConstraints({ (make) -> Void in
            make.edges.equalToSuperview()
        })
        
        // MARK: 数字
        let number1 = KeyView(withKey: Key(withTitle: "1", andType: .number, typeId: "1"))      //1
        let number2 = KeyView(withKey: Key(withTitle: "2", andType: .number, typeId: "2"))      //2
        let number3 = KeyView(withKey: Key(withTitle: "3", andType: .number, typeId: "3"))      //3
        let number4 = KeyView(withKey: Key(withTitle: "4", andType: .number, typeId: "4"))      //4
        let number5 = KeyView(withKey: Key(withTitle: "5", andType: .number, typeId: "5"))      //5
        let number6 = KeyView(withKey: Key(withTitle: "6", andType: .number, typeId: "6"))      //6
        let number7 = KeyView(withKey: Key(withTitle: "7", andType: .number, typeId: "7"))      //7
        let number8 = KeyView(withKey: Key(withTitle: "8", andType: .number, typeId: "8"))      //8
        let number9 = KeyView(withKey: Key(withTitle: "9", andType: .number, typeId: "9"))      //9
        let number0 = KeyView(withKey: Key(withTitle: "0", andType: .number, typeId: "0"))      //0
        let number00 = KeyView(withKey: Key(withTitle: "返回", andType: .changeToNormal))
        let enKeyView = KeyView(withKey: Key(withTitle: "英文", andType: .changeToLetter, typeId: nil))
        let arrNumber = [number1, number2, number3, number4, number5, number6, number7, number8, number9, number00, number0, enKeyView]
        for view in arrNumber {
            numberView.addSubview(view)
        }
        
        addConstraintsToMid(numberView, arrNumber)
        numberView.isHidden = true
        keysDictionary["11"] = number1
        keysDictionary["22"] = number2
        keysDictionary["33"] = number3
        keysDictionary["44"] = number4
        keysDictionary["55"] = number5
        keysDictionary["66"] = number6
        keysDictionary["77"] = number7
        keysDictionary["88"] = number8
        keysDictionary["99"] = number9
        keysDictionary["00"] = number0
        keysDictionary["back"] = number00
        keysDictionary["en2"] = enKeyView
        
        //加线
        let lineBanner0 = UIView()
        lineBanner0.backgroundColor = bannerLineColor
        let lineBanner1 = UIView()
        lineBanner1.backgroundColor = bannerLineColor
        bannerView.addSubview(lineBanner0)
        bannerView.addSubview(lineBanner1)
        lineBanner0.snp.makeConstraints({ (make) -> Void in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(lineThickness)
        })
        lineBanner1.snp.makeConstraints({ (make) -> Void in
            make.top.equalTo(bannerHeight*2/5)
            make.left.right.equalToSuperview()
            make.height.equalTo(lineThickness)
        })
        
        let lineMid0 = UIView(); lineMid0.backgroundColor = lineColor
        let lineMid1 = UIView(); lineMid1.backgroundColor = lineColor
        let lineMid2 = UIView(); lineMid2.backgroundColor = lineColor
        let lineMid3 = UIView(); lineMid3.backgroundColor = lineColor
        let lineMid4 = UIView(); lineMid4.backgroundColor = lineColor
        let lineMid5 = UIView(); lineMid5.backgroundColor = lineColor
        let lineMid6 = UIView(); lineMid6.backgroundColor = lineColor
        let lineMid7 = UIView(); lineMid7.backgroundColor = lineColor
        bottomView.addSubview(lineMid0)
        bottomView.addSubview(lineMid1)
        bottomView.addSubview(lineMid2)
        bottomView.addSubview(lineMid3)
        bottomView.addSubview(lineMid4)
        bottomView.addSubview(lineMid5)
        bottomView.addSubview(lineMid6)
        bottomView.addSubview(lineMid7)
        // 横线1
        lineMid0.snp.makeConstraints({ (make) -> Void in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(lineThickness)
        })
        // 横线2
        lineMid1.snp.makeConstraints({ (make) -> Void in
            make.top.equalTo(view11.snp.bottom)
            make.left.equalTo(centerView)
            make.right.equalToSuperview()
            make.height.equalTo(lineThickness)
        })
        // 横线3
        lineMid2.snp.makeConstraints({ (make) -> Void in
            make.top.equalTo(view21.snp.bottom)
            make.left.equalTo(centerView)
            make.height.equalTo(lineThickness)
            make.right.equalToSuperview()
        })
        // 横线4
        lineMid3.snp.makeConstraints({ (make) -> Void in
            make.top.equalTo(view31.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalTo(centerView)
            make.height.equalTo(lineThickness)
        })
        // 竖线1
        lineMid4.snp.makeConstraints({ (make) -> Void in
            make.top.bottom.equalToSuperview()
            make.left.equalTo(centerView)
            make.width.equalTo(lineThickness)
        })
        // 竖线2
        lineMid5.snp.makeConstraints({ (make) -> Void in
            make.top.bottom.equalToSuperview()
            make.left.equalTo(view12)
            make.width.equalTo(lineThickness)
        })
        // 竖线4
        lineMid6.snp.makeConstraints({ (make) -> Void in
//            make.top.equalToSuperview()
//            make.bottom.equalTo(view33)
            make.top.bottom.equalToSuperview()
            make.left.equalTo(view13)
            make.width.equalTo(lineThickness)
        })
        // 竖线5
        lineMid7.snp.makeConstraints({ (make) -> Void in
            make.top.bottom.equalToSuperview()
            make.left.equalTo(rightView)
            make.width.equalTo(lineThickness)
        })
        
        // 给按键添加事件
        addTargetToKeys(keysDictionary)
    }
    
    func addConstraintsToMid(_ centerView: UIView, _ arr: [KeyView]) {
        var top = centerView.snp.top
        var left = centerView.snp.left
        for (index, view) in arr.enumerated() {
//            if index == 10 {
//                view.snp.makeConstraints({ (make) -> Void in
//                    make.height.equalToSuperview().dividedBy(4)
//                    make.right.equalToSuperview()
//                    make.left.equalTo(left)
//                    make.top.equalTo(top)
//                })
//                break
//            }
            if index % 3 == 2 {
                view.snp.makeConstraints({ (make) -> Void in
                    make.height.equalToSuperview().dividedBy(4)
                    make.width.equalToSuperview().dividedBy(3)
                    make.left.equalTo(left)
                    make.top.equalTo(top)
                })
                top = view.snp.bottom
                left = centerView.snp.left

            } else {
                view.snp.makeConstraints({ (make) -> Void in
                    make.height.equalToSuperview().dividedBy(4)
                    make.width.equalToSuperview().dividedBy(3)
                    make.left.equalTo(left)
                    make.top.equalTo(top)
                })
                left = view.snp.right
            }
        }
    }
    
    // 布局候选词视图
    func addViewsToBanner() {
        // 拼音显示label
        pinyinLabel.textColor = optionColor
        bannerView.addSubview(pinyinLabel)
        pinyinLabel.snp.makeConstraints({ (make) -> Void in
            make.left.equalTo(10)
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.4)
        })
        
        // 键盘收起按键
        closeButton.backgroundColor = UIColor.white
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        bannerView.addSubview(closeButton)
        closeButton.snp.makeConstraints { (make) in
            make.right.bottom.equalToSuperview()
            make.top.equalTo(pinyinLabel.snp.bottom).offset(lineThickness)
            make.width.equalTo(symbolCollection)
        }

        // 添加左阴影
        closeButton.layer.shadowColor = UIColor.lightGray.cgColor
        closeButton.layer.shadowOffset = CGSize(width: -5, height: 0)
        closeButton.layer.shadowOpacity = 0.1

        let closeIcon = UIImageView()
        closeIcon.image = UIImage(named: "keyboard_close")
        closeButton.addSubview(closeIcon)
        closeIcon.snp.makeConstraints { (make) in
            make.width.equalTo(20)
            make.height.equalTo(12)
            make.center.equalToSuperview()
        }

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        layout.minimumLineSpacing = 20
        layout.minimumInteritemSpacing = 10
        wordsQuickCollection = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        wordsQuickCollection.showsHorizontalScrollIndicator = false
        wordsQuickCollection.backgroundColor = UIColor.clear
        wordsQuickCollection.delaysContentTouches = false
        wordsQuickCollection.canCancelContentTouches = true
        wordsQuickCollection.alwaysBounceHorizontal = true
        wordsQuickCollection.delegate = self
        wordsQuickCollection.dataSource = self
        wordsQuickCollection.register(WordsCell.self, forCellWithReuseIdentifier: "WordsCell")
        
        bannerView.addSubview(wordsQuickCollection)
        wordsQuickCollection.snp.makeConstraints({ (make) -> Void in
            make.top.equalTo(pinyinLabel.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalTo(closeButton.snp.left)
            make.bottom.equalToSuperview()
        })
    }
    
    // MARK: - UICollectionView delegate
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView === self.wordsQuickCollection {
            // 候选词视图如果在输入中，则显示候选词
//            if isTyping {
                return pinyinStore.words.count
//            } else {
//                return 0
//            }
        } else {
            // 左侧：如果在输入中，则显示拼音；否则显示符号
            if isTyping {
                return pinyinStore.pinyins.count
            } else {
                return symbolStore.allSymbols.count
            }
        }
    }
    
    // 上下间距
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == self.wordsQuickCollection {
            return 20
        }
        return 0
    }

    // 左右间距
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == self.wordsQuickCollection {
            return 20
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == self.wordsQuickCollection {
            let pinyin = pinyinStore.words[indexPath.row] as NSString
            let size = pinyin.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: bannerHeight * 2.0 / 5.0), options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .title3)], context: nil).size
            return CGSize(width: size.width + 6, height: size.height)
        } else {
            return CGSize(width: leftSymbolWidth, height: 40.5)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView === self.wordsQuickCollection {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WordsCell", for: indexPath) as! WordsCell
//            if isTyping {
                cell.wordslabel.text = pinyinStore.words[indexPath.row]
//            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SymbolCell", for: indexPath) as! SymbolCell
            
            if isTyping {
                cell.addPinyin(pinyinStore.pinyins[indexPath.row], index: indexPath.row)
            } else {
                cell.addKey(symbolStore.allSymbols[indexPath.row])
            }
            
            cell.keyView?.addTarget(self, action: #selector(tapOtherKey(_:)), for: .touchUpInside)
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if collectionView === self.wordsQuickCollection {
            // 联想词点击
            if pinyinStore.words.count > 0 && idString == "" {
                let word = pinyinStore.words[indexPath.row]
                let proxy = (delegate.textDocumentProxy) as UITextDocumentProxy
                proxy.insertText(word)
            }
            
            // 选择了字
            isClickSpaceOrWord = true

//            proxy.insertText(pinyinStore.words[indexPath.row])
            // 将当前选中的字保存
            let word = pinyinStore.words[indexPath.row]
            pinyinStore.wordSelected.append(word)
            
            // 如果点击的内容为历史记录，则直接将内容放到文本框中，不再进行下一个文字选择
            if pinyinStore.isInHistory && indexPath.row < pinyinStore.historyCount {
                pinyinStore.allPinyins.append(pinyinStore.splitedPinyinString)
                pinyinStore.pinyins.removeAll()         //就是清除数据
                pinyinStore.needSearchHistory = false
            } else {
                pinyinStore.isInHistory = false
                pinyinStore.needSearchHistory = false
                // 根据当前选中的下标，从对应的拼音中找到汉字words
                pinyinStore.currentIndex = selectedIndex
                let length = pinyinStore.pinyinSelected.count
                var index = pinyinStore.indexStore.last!
                if saveIndex {
                    index += length
                    pinyinStore.indexStore.append(index)
                    pinyinStore.allPinyins.append(pinyinStore.pinyinSelected)
                }
            }
            
            pinyinStore.pinyinSelected = ""
            saveIndex = true
            selectedIndex = 0
            updateTypingViews()
        }
    }
    
    func updateTypingViews() {
        
        // 是否点击了空格或者选择了字
        if isClickSpaceOrWord {
            pinyinStore.currentIndex = 0
            pinyinStore.pinyinSelected = ""
        }
        isClickSpaceOrWord = false

        if !pinyinStore.isInHistory || pinyinStore.needSearchHistory {      //如果不在历史中或者需要继续查询历史
            pinyinStore.id = idString                                       //在历史中且不要查询历史就不会进if
        }
        
        if idString == "" {
            isTyping = false
            saveIndex = true
            pinyinStore.clearData()
        }
        
        if isTyping {
            if pinyinStore.pinyins.count == 0 {
                let proxy = (delegate.textDocumentProxy) as UITextDocumentProxy
                var text = ""
                for str in pinyinStore.wordSelected {
                    text += str
                }
                proxy.insertText(text)
                let pinyin = PinyinStore.splitPinyinStrings(pinyinStore.allPinyins)
                CacheTable.cache(key: pinyinStore.id, pinyin: pinyin, word: text)
                isTyping = false
                saveIndex = true
                pinyinStore.clearData()
                idString = ""
                
                // 根据当前输入词语，查找联想词
                if text.count > 0 , let associationWords = CommonTable.queryAssociateWords(text: text) {
                    pinyinStore.words = associationWords
                }
            }
        }
        
        
        if isTyping {
            // 拼音显示
            self.pinyinLabel.text = pinyinStore.splitedPinyinString
        } else {
            self.pinyinLabel.text = ""
            saveIndex = true
        }
        

        
        UIView.performWithoutAnimation {
            self.symbolCollection.reloadData()
            self.wordsQuickCollection.reloadSections(NSIndexSet(index: 0) as IndexSet)
            self.wordsQuickCollection.contentOffset = CGPoint.zero
            //            self.wordsQuickCollection?.layoutIfNeeded()
            //            self.wordsQuickCollection?.reloadData()
        }
        
    }
    
    // MARK: - 按键点击事件
    func addTargetToKeys(_ dict: [String: KeyView]) {
        for (key, value) in dict {
            switch key {
            case "2","3","4","5","6","7","8","9":
                value.addTarget(self, action: #selector(tapNormalKey(_:)), for: .touchDown)
            // touchUpInside类型
            case "en", "en2":
                value.addTarget(self, action: #selector(changeKeyboardTypeToLetter), for: .touchUpInside)
            default:
                value.addTarget(self, action: #selector(tapOtherKey(_:)), for: .touchDown)
            }
        }
    }
    
    // 切换键盘类型
    @objc func changeKeyboardTypeToLetter() {
        delegate.keyboardType = .letter
    }
    
    // 点击九宫格拼音按键
    @objc func tapNormalKey(_ sender: KeyView) {
        // 正在输入
        isTyping = true
        // 九宫格按键组合
        idString += sender.key.typeId!
        
        // 是否点击了空格或者选择了字
        isClickSpaceOrWord = false

        // true为没有选中拼音，false为已经选中拼音
        if saveIndex == false {
            pinyinStore.currentIndex = 0
            pinyinStore.pinyinSelected = ""
            pinyinStore.indexStore.removeLast()
            pinyinStore.allPinyins.removeLast()

            saveIndex = true
        }
        
        // 候选词滑动视图复位
        self.wordsQuickCollection.setContentOffset(CGPoint.zero, animated: false)
        updateTypingViews()
    }
    
    // 九宫格按键以外的按键
    @objc func tapOtherKey(_ sender: KeyView) {
        let proxy = (delegate.textDocumentProxy) as UITextDocumentProxy

        isClickSpaceOrWord = false

        let type = sender.key.type
        switch type {
        case .pinyin:
            pinyinStore.currentIndex = sender.key.index!
            pinyinStore.isInHistory = false
            pinyinStore.needSearchHistory = false
            selectedIndex = sender.key.index!
            let length = pinyinStore.pinyinSelected.count
            
            if !saveIndex {
                pinyinStore.indexStore.removeLast()
                pinyinStore.allPinyins.removeLast()
            }
            pinyinStore.allPinyins.append(pinyinStore.pinyinSelected)
            var index = pinyinStore.indexStore.last!
            index += length
            pinyinStore.indexStore.append(index)
            saveIndex = false
            
            UIView.performWithoutAnimation {
                self.wordsQuickCollection?.reloadSections(NSIndexSet(index: 0) as IndexSet)
                self.wordsQuickCollection.contentOffset = CGPoint.zero
            }
            self.pinyinLabel.text = pinyinStore.splitedPinyinString

        case .symbol, .number:
            proxy.insertText(sender.key.outputText!)
            
        case .space:
            isClickSpaceOrWord = true
            if isTyping {
                let word = pinyinStore.words[0]
                pinyinStore.wordSelected.append(word)
                
                if pinyinStore.isInHistory {
                    pinyinStore.allPinyins.append(pinyinStore.splitedPinyinString)
                    pinyinStore.pinyins.removeAll()         //就是清除数据
                    pinyinStore.needSearchHistory = false
                } else {
                    pinyinStore.currentIndex = selectedIndex
                    let length = pinyinStore.pinyinSelected.count
                    var index = pinyinStore.indexStore.last!
                    if saveIndex {
                        index += length
                        pinyinStore.indexStore.append(index)
                        pinyinStore.allPinyins.append(pinyinStore.pinyinSelected)
                    }
                }
                
                pinyinStore.pinyinSelected = ""
                saveIndex = true
                updateTypingViews()
                selectedIndex = 0

            } else {
                proxy.insertText(" ")
            }

        case .backspace:
            if isTyping {
                if pinyinStore.indexStore.count > 1 {       //有选中的拼音或者字
                    pinyinStore.indexStore.removeLast()
                    pinyinStore.allPinyins.removeLast()
                    pinyinStore.currentIndex = 0
                    pinyinStore.pinyinSelected = ""

                    if saveIndex && pinyinStore.wordSelected.count > 0 {    //若没有选中拼音且有选中字
                        pinyinStore.wordSelected.removeLast()
                    }

                    saveIndex = true
                    updateTypingViews()

                } else {
                    idString.removeLast()
//                    idString.remove(at: idString.index(before: idString.endIndex))
                    pinyinStore.isInHistory = false
                    updateTypingViews()

                }
            } else {
                proxy.deleteBackward()
                // 如果没有输入拼音，则将候选词清空
                if idString.count == 0 {
                    reset()
                }
            }

        case .return:
            if isTyping {
                proxy.insertText((self.pinyinLabel.text)!)
                idString = ""
                updateTypingViews()
            } else {
                proxy.insertText("\n")
            }
            
        case .reType:
            if isTyping {
                reset()
            }
        case .changeToNumber:
            numberView.isHidden = false
        case .changeToNormal:
            numberView.isHidden = true
//            allSymbolCollection?.isHidden = true
        case .changeToSymbol:
            // 点击符号：清除输入，并把符号显示到候选区
            reset()
            pinyinStore.words = SymbolKeyStore.defaultKeys
            UIView.performWithoutAnimation {
                self.symbolCollection.reloadData()
                self.wordsQuickCollection.reloadSections(NSIndexSet(index: 0) as IndexSet)
                self.wordsQuickCollection.contentOffset = CGPoint.zero
            }
            
//            allSymbolCollection?.isHidden = false
        default:
            break
        }
    }
    
    // 重置输入法
    @objc func reset() {
        idString = ""
        saveIndex = true
        pinyinStore.clearData()
        updateTypingViews()
    }
    
    // 收起键盘
    @objc func close() {
        delegate.dismissKeyboard()
    }
}

// MARK: 添加到History     结构为   0 pinyin    1 word  2 frequence
//func saveToHistory(withId key: String, pinyin: String, word: String) {
//    if let dict = historyDictionary {
//        let value = dict.value(forKey: key) as? Array<[String]>
//        if value != nil {
//            var pinyins = value![0]
//            var words = value![1]
//            var frequence = value![2]
//            var oldIndex: Int = 0
//            var index = 0
//            var fre = 0
//            var flag = false
//            for (i, str) in words.enumerated() {
//                if str == word {
//                    oldIndex = i
//                    fre = Int(frequence[i])!
//                    fre += 1
//                    flag = true
//                    break
//                }
//            }
//            for (i, str) in frequence.enumerated() {
//                let num = Int(str)!
//                if num < fre {
//                    index = i
//                    break
//                }
//            }
//
//            if flag {       //有这个值
//                words.remove(at: oldIndex)
//                pinyins.remove(at: oldIndex)
//                frequence.remove(at: oldIndex)
//
//                words.insert(word, at: index)
//                pinyins.insert(pinyin, at: index)
//                frequence.insert("\(fre)", at: index)
//            } else {
//                words.append(word)
//                pinyins.append(pinyin)
//                frequence.append("1")
//            }
//            dict.setObject([pinyins, words, frequence], forKey: key as NSCopying)
//            dict.write(toFile: historyPath, atomically: true)
//
//        } else {
//            dict.setObject([[pinyin], [word], ["1"]], forKey: key as NSCopying)
//            dict.write(toFile: historyPath, atomically: true)
//        }
//    } else {
//        let dict = NSMutableDictionary()
//        dict.setObject([[pinyin], [word], ["1"]], forKey: key as NSCopying)
//        dict.write(toFile: historyPath, atomically: true)
//    }
//}
