//
//  StoreConfiguration.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/7.
//

import Foundation
import OrderedCollections

/// 提供读取plist配置文件的静态方法
@available(tvOS 15.0, *)
public struct StoreConfiguration {
    
    private init() {}
    
    /// 阅读产品定义属性列表的内容
    /// - Returns: 如果列表已读取，则返回一组ProductId，否则返回nil
    public static func readConfigFile() -> OrderedSet<ProductId>? {
        
        guard let result = PropertyFile.read(filename: StoreConstants.ConfigFile) else {
            StoreLog.event(.configurationNotFound)
            StoreLog.event(.configurationFailure)
            return nil
        }
        
        guard result.count > 0 else {
            StoreLog.event(.configurationEmpty)
            StoreLog.event(.configurationFailure)
            return nil
        }
        
        guard let values = result[StoreConstants.ConfigFile] as? [String] else {
            StoreLog.event(.configurationEmpty)
            StoreLog.event(.configurationFailure)
            return nil
        }
        
        StoreLog.event(.configurationSuccess)

        return OrderedSet<ProductId>(values.compactMap { $0 })
    }
}
