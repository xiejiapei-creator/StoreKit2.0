//
//  SubscriptionInfo.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/8.
//

import StoreKit

/// 有关用户订阅的订阅组中最高服务级别产品的信息
@available(tvOS 15.0, *)
public struct SubscriptionInfo: Hashable {
    
    /// 产品
    public var product: Product?
    
    /// 订阅组product的名称所属
    public var subscriptionGroup: String?
    
    /// 订阅的最新StoreKit验证购买交易记录。如果验证失败，则为nil
    public var latestVerifiedTransaction: Transaction?
    
    /// StoreKit验证过的订阅续订的交易，如果验证失败，则为nil
    public var verifiedSubscriptionRenewalInfo:  Product.SubscriptionInfo.RenewalInfo?
    
    /// 有关订阅的信息
    public var subscriptionStatus: Product.SubscriptionInfo.Status?
}
