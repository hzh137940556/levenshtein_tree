
//
//  AirportModel.swift
//  AirportData
//
//  Created by Eachpal on 2020/2/5.
//  Copyright © 2020 Eachpal. All rights reserved.
//

import UIKit
struct AirportModel {
    var id: String?
    var fullName: String?
    var code3: String?
    var code4: String?
    var city: String?
    var country: String?
    var length: Int?
}
class Node {
    var length: Int = -1
    var words = ""
    var left: Node?
    var right: Node?
    var model: AirportModel?
}
class Tree {
    private var pRoot: Node?
    var time: CFTimeInterval = 0
    var levenshteinCount = 0
    func insert(str: String, airPortModel: AirportModel) {
        
        if nil != pRoot {
            guard var pPre = pRoot else {return}
            var pCur = pPre.left
            while true {
                let word = pPre.words
                let distance = word.levenshtein(str)
                if 0 == distance { break }
                if nil == pCur {
                    let nowNode = Node()
                    nowNode.words = str
                    nowNode.model = airPortModel
                    nowNode.length = distance
                    pCur = nowNode
                    pCur?.left = nil
                    pCur?.right = nil
                    pPre.left = pCur
                    break
                } else if let pCurT = pCur, pCurT.length > distance {
                    let nowNode = Node()
                    nowNode.words = str
                    nowNode.model = airPortModel
                    nowNode.length = distance
                    nowNode.right = pCur
                    pPre.left = nowNode
                    break
                } else {
                    while(nil != pCur && pCur!.length<distance) {
                        pPre = pCur!
                        pCur = pCur!.right
                    }
                    if (nil != pCur && pCur!.length == distance) {
                        pPre = pCur!
                        pCur = pCur!.left
                    } else {
                        let nowNode = Node()
                        nowNode.words = str
                        nowNode.model = airPortModel
                        nowNode.length = distance
                        nowNode.left = nil
                        nowNode.right = pCur
                        pPre.right = nowNode
                        break
                    }
                }
            }
            
        } else {
            let nowNode = Node()
            nowNode.words = str
            nowNode.model = airPortModel
            nowNode.length = 0
            pRoot = nowNode
        }
    }
    func find(pRoot: Node?, str: String, limit_num: Int, result: inout [AirportModel]) {
        if pRoot == nil {
            return
        }
        levenshteinCount += 1
        let word = pRoot!.words
        let time = Date().timeIntervalSince1970
        let distance = word.levenshtein(str)
        let time2 = Date().timeIntervalSince1970
        self.time += time2-time
        if distance < limit_num {
            pRoot?.model?.length = distance
            result.append(pRoot!.model!)
            //print("step count \(distance)")
        }
        var pCur: Node? = pRoot!.left
        while(pCur != nil) {
            if (pCur!.length<(distance+limit_num) &&
                pCur!.length>(distance-limit_num)) {
                find(pRoot: pCur!, str: str, limit_num: limit_num, result: &result)
            }
            //find(pRoot: pCur!, str: str, limit_num: limit_num, result: &result)
            pCur = pCur?.right
        }
    }
    public func search(str: String, limit_num: Int, result: inout [AirportModel]) {
        let date = Date().timeIntervalSince1970
        find(pRoot: pRoot, str: str, limit_num: limit_num, result: &result)
        let date2 = Date().timeIntervalSince1970
        print("查询str = \(str)   耗时 = \(date2-date)")
    }
}
func parseStrToAirportModel(airportItemStr: String) -> AirportModel {
    var airportModel = AirportModel.init()
    let arrayItemProperty = airportItemStr.split(separator: ",")
    for i in 0..<arrayItemProperty.count {
        let property1 = arrayItemProperty[i]
        let property = String(property1)
        switch i {
        case 0:
        airportModel.id = property
        case 1:
        airportModel.fullName = property
        case 2:
        airportModel.city = property
        case 3:
        airportModel.country = property
        case 4:
        airportModel.code3 = property
        case 5:
        airportModel.code4 = property
        //airportModel.longitude = Double(property) ?? 0
        default: break
        }
    }
    return airportModel
}

class AirportManager {
    public static let shared = AirportManager()
    private var tree = Tree()
    private let dataUrl: URL = {
       let mgr = FileManager.default
       let cachePath = mgr.urls(for: .cachesDirectory,
                                                in: .userDomainMask)[0]
       let logURL = cachePath.appendingPathComponent("airportData")
       if !mgr.fileExists(atPath: logURL.path) {
           do {
               try mgr.createDirectory(atPath: logURL.path, withIntermediateDirectories: true, attributes: nil)
           } catch {
               print("创建airportData 目录失败 ")
           }
           if mgr.fileExists(atPath: logURL.path) {
               print("创建airportData 目录成功")
           } else {
               print("创建airportData 目录失败")
           }
       }
       return logURL
    }()
    /// 创建串行队列，保证执行查询是同步的。
    private var queue: DispatchQueue = DispatchQueue.init(label: "haha")
    func searchLocal(str: String, limit_num: Int, completion: (([AirportModel]) -> Void)?) {
        queue.async {
            var result = [AirportModel]()
            self.tree.time = 0
            self.tree.levenshteinCount = 0
            self.tree.search(str: str, limit_num: limit_num, result: &result)
            print("关于计算编辑距离的耗时： \(self.tree.time), 一共调用编辑距离: \(self.tree.levenshteinCount)")
            result.sort(by: {$0.length!<$1.length!})
            completion?(result)
        }
    }
    func downloadAirport() {
        let url = URL.init(string: "https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat")
        let urlRequest = URLRequest(url: url!)
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest) { (data, response, error) in
            // check for error
            guard error == nil else {
                print("Error: error is not nil")
                return
            }
            // check for data
            guard let responseData = data else {
                print("Error: data is nil")
                return
            }
            var responseStr = String(data: responseData, encoding: String.Encoding.utf8)!
            responseStr = responseStr.replacingOccurrences(of: "\"", with: "")
            
            self.saveString(str: responseStr)
            self.queue.async {
                self.initTreeData()
            }
            //print("---------\(responseStr)")
        }
        task.resume()
    }
    /// 初始化树
    func initTreeData() {
        queue.async {
            if self.getData() == "" {
                self.downloadAirport()
                return
            }
            self.tree = Tree()
            let str = self.getData().replacingOccurrences(of: "\"", with: "")
            let date = Date().timeIntervalSince1970
            let arrayItem = str.split(separator: "\n")
            arrayItem.forEach { (item) in
                let airportModel = parseStrToAirportModel(airportItemStr: String(item))
                if let code3 = airportModel.fullName {
                    self.tree.insert(str: code3, airPortModel: airportModel)
                }
            }
            let date2 = Date().timeIntervalSince1970
            print("解析文件耗时  \(date2-date) s")
        }
    }
    /// 保存字符串到本地
    /// - Parameter str: <#str description#>
    func saveString(str: String) {
        queue.async {
            let path = self.dataUrl.appendingPathComponent("data.txt")
            print("保存字符串 url ==== \(path)")
            do {
                try str.write(to: path, atomically: true, encoding: String.Encoding.utf8)
            } catch {
                print("保存机场列表字符串报错 \(error)")
            }
        }
    }

    /// 从本地读取字符串
    func getData() -> String {
      var value = ""
      do {
          let date = Date().timeIntervalSince1970
          let data = try Data(contentsOf: dataUrl.appendingPathComponent("data.txt"))
          let date2 = Date().timeIntervalSince1970
          let cha = date2-date
          print("加载文件耗时  \(cha) s")
          let str = String(data: data, encoding: String.Encoding.utf8) ?? ""
          value = str
          print("data size \(Double(data.count)/1024/1024)")
      } catch {
          print("get data error \(error)")
      }
      return value
    }
}
