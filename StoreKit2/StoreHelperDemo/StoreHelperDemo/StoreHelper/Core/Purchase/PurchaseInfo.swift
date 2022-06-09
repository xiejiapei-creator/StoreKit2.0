//
//  PurchaseInfo.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/8.
//

import StoreKit

/// 非消耗品采购的汇总信息
@available(tvOS 15.0, *)
public struct PurchaseInfo {
    
    /// 产品
    public var product: Product

    /// 使用StoreKit验证非消耗品的交易。如果验证失败，则为nil
    public var latestVerifiedTransaction: Transaction?
}

