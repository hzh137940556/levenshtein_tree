//
//  ViewController.swift
//  AirportData
//
//  Created by Eachpal on 2020/2/4.
//  Copyright © 2020 Eachpal. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    private let tree = Tree()
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var limitTF: UITextField!
    private var task: Task?
    private var datasource: [AirportModel] = []
    private var limit_count: Int = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        AirportManager.shared.initTreeData()
    }

    @IBAction func clickBegin(_ sender: Any) {
        testTreeValid()
    }
    
    
    /// 测试树的完整性
    private func testTreeValid() {
//        let str = getData().replacingOccurrences(of: "\"", with: "")
//        let arrayItem = str.split(separator: "\n")
//        arrayItem.forEach { (item) in
//            let airportModel = parseStrToAirportModel(airportItemStr: String(item))
//            var result = [AirportModel]()
//            self.tree.search(str: airportModel.code3!, limit_num: 1, result: &result)
//            if result.count != 1 {
//                print("error")
//            } else {
//                result.forEach { (model) in
//                    print("search: \(airportModel.code3!) code3 = \(model.code3!)")
//                }
//            }
//        }
    }
    
    
    /// 执行搜索
    /// - Parameter str: <#str description#>
    private func search(str: String) {
        //self.tree.search(str: str, limit_num: self.limit_count, result: &result)
        
        AirportManager.shared.searchLocal(str: str, limit_num: limit_count) { (result) in
            DispatchQueue.main.async {
                self.datasource = result
                self.tableView.reloadData()
                for item in result where item.code3 == "SFO" {
                    print("success ")
                }
            }
        }
    }
    @IBAction func limitTFChanged(_ sender: Any) {
        if let text = limitTF.text, text != "" {
            limit_count = Int(text) ?? 0
        } else {
            limit_count = 0
        }
    }
    @IBAction func searchTFChanged(_ sender: Any) {
        cancelTask(task: self.task)
        self.task = delayTask(time: 0.5) {
            if let text = self.textField.text, text != "" {
                self.search(str: text)
                print("search text = \(text)")
            } else {
                self.datasource = []
                self.tableView.reloadData()
            }
        }
        
    }
    
}

extension ViewController: UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell.init(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "cell")
        }
        let model = datasource[indexPath.row]
        cell?.textLabel?.text = model.code3
        cell?.detailTextLabel?.text = model.fullName
        return cell!
    }
    
}



extension String {
    
    /// 获取两个字符串之间的编辑距离
    /// - Parameter other: <#other description#>
    public func levenshtein(_ other: String) -> Int {
        let sCount = self.count
        let oCount = other.count

        guard sCount != 0 else {
            return oCount
        }

        guard oCount != 0 else {
            return sCount
        }

        let line : [Int]  = Array(repeating: 0, count: oCount + 1)
        var mat : [[Int]] = Array(repeating: line, count: sCount + 1)

        for i in 0...sCount {
            mat[i][0] = i
        }

        for j in 0...oCount {
            mat[0][j] = j
        }

        for j in 1...oCount {
            for i in 1...sCount {
                if self[i - 1] == other[j - 1] {
                    mat[i][j] = mat[i - 1][j - 1]       // no operation
                }
                else {
                    let del = mat[i - 1][j] + 1         // deletion
                    let ins = mat[i][j - 1] + 1         // insertion
                    let sub = mat[i - 1][j - 1] + 1     // substitution
                    mat[i][j] = min(min(del, ins), sub)
                }
            }
        }

        return mat[sCount][oCount]
    }
}
extension String {
    subscript(index: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: index)]
    }
}

public typealias Task = (_ cancel: Bool) -> Void

public func delayTask(time: TimeInterval, task: @escaping () -> Void) -> Task? {

    func dispatch_later(block: @escaping () -> Void) {
        let t = DispatchTime.now() + time
        DispatchQueue.main.asyncAfter(deadline: t, execute: block)
    }
    var closure: (() -> Void)? = task
    var result: Task?

    let delayedClosure: Task = {
        cancel in
        if let internalClosure = closure {
            if cancel == false {
                DispatchQueue.main.async(execute: internalClosure)
            }
        }
        closure = nil
        result = nil
    }

    result = delayedClosure

    dispatch_later {
        if let delayedClosure = result {
            delayedClosure(false)
        }
    }
    return result
}

public func cancelTask(task: Task?) {
    task?(true)
}

public func delay(time: TimeInterval, task: @escaping () -> Void) {

    func dispatch_later(block: @escaping () -> Void) {
        let t = DispatchTime.now() + time
        DispatchQueue.main.asyncAfter(deadline: t, execute: block)
    }
    var closure: (() -> Void)? = task
    var result: Task?

    let delayedClosure: Task = {
        cancel in
        if let internalClosure = closure {
            if cancel == false {
                DispatchQueue.main.async(execute: internalClosure)
            }
        }
        closure = nil
        result = nil
    }

    result = delayedClosure

    dispatch_later {
        if let delayedClosure = result {
            delayedClosure(false)
        }
    }
}

/*
//调用
delay(2) { logger.info("2 秒后输出") }

//取消
let task = delay(5) { logger.info("拨打 110") }

//仔细想一想,还是取消为妙..
cancel(task)
*/
