//
//  SubscriptionHelper.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/9.
//

import StoreKit
import OrderedCollections
import SwiftUI

/// 订阅的帮助器类
///
/// 此类中的方法要求自动续订订阅产品ID采用命名约定
/// com.{author}.subscription.{subscription-group-name}.{product-name}
/// 比如：com.xiejiapei.subscription.vip.bronze
///
/// 服务级别取决于`Products.plist`文件中订阅组内ID的排序
@available(tvOS 15.0, *)
public struct SubscriptionHelper {
    
    weak public var storeHelper: StoreHelper?
    
    private static let productIdSubscriptionName = "subscription"
    private static let productIdSeparator = "."
    
    /// 确定在Products.plist中定义的订阅产品ID集中存在的组名称
    /// - Returns: 返回StoreHelper持有的订阅产品ID的OrderedSet中存在的组名
    public func groups() -> OrderedSet<String>? {
        
        guard let store = storeHelper else { return nil }
        var subscriptionGroups = OrderedSet<String>()
        
        if let spids = store.subscriptionProductIds {
            spids.forEach { productId in
                if let group = groupName(from: productId) {
                    subscriptionGroups.append(group)
                }
            }
        }
        
        return subscriptionGroups.count > 0 ? subscriptionGroups : nil
    }
    
    /// 按值的顺序返回属于命名订阅组的产品ID集
    /// - Parameter group: 组名称
    /// - Returns: 按值的顺序返回属于命名订阅组的产品ID集
    public func subscriptions(in group: String) -> OrderedSet<ProductId>? {
        
        guard let store = storeHelper else { return nil }
        var matchedProductIds = OrderedSet<ProductId>()
        
        if let spids = store.subscriptionProductIds {
            spids.forEach { productId in
                if let matchedGroup = groupName(from: productId), matchedGroup.lowercased() == group.lowercased() {
                    matchedProductIds.append(productId)
                }
            }
        }
        
        return matchedProductIds.count > 0 ? matchedProductIds : nil
    }
    
    /// 提取 ProductId 中存在的订阅组的名称
    /// - Parameter productId: 要从中提取订阅组名称的 ProductId
    /// - Returns: 返回 ProductId 中存在的订阅组的名称
    public func groupName(from productId: ProductId) -> String? {
        
        let components = productId.components(separatedBy: SubscriptionHelper.productIdSeparator)
        for i in 0...components.count-1 {
            if components[i].lowercased() == SubscriptionHelper.productIdSubscriptionName {
                if i+1 < components.count { return components[i+1] }
            }
        }
        
        return nil
    }
    
    /// 为订阅组中的 ProductId 提供服务级别
    ///
    /// - Parameters:
    ///   - group: 订阅组名称
    ///   - productId: 您所需的 ProductId 服务级别
    /// - Returns: 订阅组中 ProductId 的服务级别，如果找不到 ProductId ，则为-1
    public func subscriptionServiceLevel(in group: String, for productId: ProductId) -> Int {

        guard let products = subscriptions(in: group) else { return -1 }
        
        var index = products.count-1
        for i in 0...products.count-1 {
            if products[i] == productId { return index }
            index -= 1
        }
        
        return -1
    }
    
    /// 从订阅产品列表中获取所有订阅组
    /// 对于每个组，获取最高订阅级别的产品
    public func groupSubscriptionInfo() async -> OrderedSet<SubscriptionInfo>? {
        
        guard let store = storeHelper else { return nil }
        var subscriptionInfo = OrderedSet<SubscriptionInfo>()
        let subscriptionGroups = store.subscriptionHelper.groups()
        
        if let groups = subscriptionGroups {
            subscriptionInfo = OrderedSet<SubscriptionInfo>()
            for group in groups {
                if let hslp = await store.subscriptionInfo(for: group) { subscriptionInfo.append(hslp) }
            }
        }
        
        return subscriptionInfo
    }
    
    /// 获取产品的 SubscriptionInfo
    /// - Parameter product: 产品
    /// - Returns: 如果产品是用户订阅的组中服务级别最高的产品，则为该产品。如果用户未订阅该产品，或者该产品不是组中服务级别最高的产品，则返回nil
    public func subscriptionInformation(for product: Product, in subscriptionInfo: OrderedSet<SubscriptionInfo>?) -> SubscriptionInfo? {
        if let si = subscriptionInfo {
            for subInfo in si {
                if let p = subInfo.product, p.id == product.id { return subInfo }
            }
        }
        
        return nil
    }
}

