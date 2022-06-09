//
//  PropertyFile.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/7.
//

import Foundation

public struct PropertyFile {
    
    /// 读取plist属性文件并返回值字典
    public static func read(filename: String) -> [String : AnyObject]? {
        if let path = Bundle.main.path(forResource: filename, ofType: "plist") {
            if let contents = NSDictionary(contentsOfFile: path) as? [String : AnyObject] {
                return contents
            }
        }
        
        return nil  // [:]
    }
}


