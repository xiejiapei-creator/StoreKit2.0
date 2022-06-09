//
//  StoreConstants.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/8.
//

import Foundation

/// 用于支持应用商店操作的常量
public struct StoreConstants {
    
    /// 返回plist配置文件的名称，其中包含ProductId列表
    public static let ConfigFile = "Products"
    
    /// 用于存储已购买产品的回退列表的UserDefaults键
    public static let PurchasedProductsFallbackKey = "PurchasedProductsFallback"
}

