//
//  SubscriptionInfoViewModel.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/9.
//

import StoreKit
import SwiftUI

/// 有关订阅产品的扩展信息，用于向用户显示信息
@available(tvOS 15.0, *)
public struct ExtendedSubscriptionInfo: Hashable {
    public var productId: ProductId                                      // 产品的唯一id
    public var name: String                                              // 产品的显示名称
    public var isPurchased: Bool                                         // 如果已购买产品，则为true
    public var productType: Product.ProductType                          // 消耗品、非消耗品、订阅等
    public var subscribed: Bool?                                         // 如果订阅了产品，则为true
    public var subscribedtext: String?                                   // 显示订阅状态的文本
    public var upgraded: Bool?                                           // 如果产品已升级，则为true
    public var autoRenewOn: Bool?                                        // 如果启用自动续订，则为true
    public var renewalPeriod: String?                                    // 显示续订期间的文本比如 "每月")
    public var renewalDate: String?                                      // 显示续订日期的文本
    public var renewsIn: String?                                         // 显示订阅续订时间的文本（例如“12天”）
    public var purchasePrice: String?                                    // 购买时支付的本地化价格
    public var purchaseDate: Date?                                       // 最近购买日期
    public var purchaseDateFormatted: String?                            // 最近购买日期格式为“yyyyMMMdd”（例如“2021年12月28日”）
    public var transactionId: UInt64?                                    // 最近购买的Transactionid。UInt64.min（如果未购买）
    public var revocationDate: Date?                                     // 应用商店撤销购买的日期（例如，由于退款等原因）
    public var revocationDateFormatted: String?                          // 撤销日期格式为“yyyyMMMdd”
    public var revocationReason: StoreKit.Transaction.RevocationReason?  // 取消购买的原因
    public var ownershipType: StoreKit.Transaction.OwnershipType?        // 私人购买或者家庭购买
}

/// 订阅产品的视图模型
@available(tvOS 15.0, *)
public struct SubscriptionInfoViewModel {
    
    @ObservedObject public var storeHelper: StoreHelper
    public var subscriptionInfo: SubscriptionInfo
    
    public init(storeHelper: StoreHelper, subscriptionInfo: SubscriptionInfo) {
        self.storeHelper = storeHelper
        self.subscriptionInfo = subscriptionInfo
    }
    
    /// 与产品订阅相关的扩展信息
    /// - Returns: 返回与产品订阅相关的扩展信息
    @MainActor public func extendedSubscriptionInfo() async -> ExtendedSubscriptionInfo? {
        guard let product = subscriptionInfo.product else { return nil }
        
        var esi = ExtendedSubscriptionInfo(productId: product.id, name: product.displayName, isPurchased: false, productType: .autoRenewable, purchasePrice: product.displayPrice)
        esi.isPurchased = (try? await storeHelper.isPurchased(productId: product.id)) ?? false
        guard esi.isPurchased else { return esi }
        esi.subscribed = true
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        
        if let state = subscriptionInfo.subscriptionStatus?.state {
            switch state {
                case .subscribed: esi.subscribedtext = "已订阅"
                case .inGracePeriod: esi.subscribedtext =  "已订阅。即将到期"
                case .inBillingRetryPeriod: esi.subscribedtext = "已订阅。续订失败"
                case .revoked: esi.subscribedtext = "订阅已撤销"
                case .expired: esi.subscribedtext = "订阅已过期"
                default:
                    esi.subscribed = false
                    esi.subscribedtext = "订阅状态未知"
            }
        }
        
        if let subscription = subscriptionInfo.product?.subscription {
            var periodUnitText: String?
            switch subscription.subscriptionPeriod.unit {
                    
                case .day:   periodUnitText = String(subscription.subscriptionPeriod.value) + "天"
                case .week:  periodUnitText = String(subscription.subscriptionPeriod.value) + "周"
                case .month: periodUnitText = String(subscription.subscriptionPeriod.value) + "月"
                case .year:  periodUnitText = String(subscription.subscriptionPeriod.value) + "年"
                @unknown default: periodUnitText = nil
            }
            
            if let put = periodUnitText { esi.renewalPeriod = "每 \(put)"}
            else { esi.renewalPeriod = "未知续订期限"}
        }
        
        if let renewalInfo = subscriptionInfo.verifiedSubscriptionRenewalInfo { esi.autoRenewOn = renewalInfo.willAutoRenew }
        else { esi.autoRenewOn = false }
        
        if let latestTransaction = subscriptionInfo.latestVerifiedTransaction, let renewalDate = latestTransaction.expirationDate {
            if latestTransaction.isUpgraded { esi.upgraded = true }
            else  {
                
                esi.upgraded = false
                esi.renewalDate = dateFormatter.string(from: renewalDate)
                
                let diffComponents = Calendar.current.dateComponents([.day], from: Date(), to: renewalDate)
                if let daysLeft = diffComponents.day {
                    if daysLeft > 1 { esi.renewsIn = "\(daysLeft) 天" }
                    else if daysLeft == 1 { esi.renewsIn! += "\(daysLeft) 天" }
                    else { esi.renewsIn = "今天" }
                }
            }
        }
        
        // 最近的交易
        guard let transaction = await storeHelper.mostRecentTransaction(for: product.id) else { return esi }
        esi.transactionId = transaction.id
        esi.purchaseDate = transaction.purchaseDate
        esi.purchaseDateFormatted = dateFormatter.string(from: transaction.purchaseDate)
        esi.revocationDate = transaction.revocationDate
        esi.revocationDateFormatted = transaction.revocationDate == nil ? nil : dateFormatter.string(from: transaction.revocationDate!)
        esi.revocationReason = transaction.revocationReason
        esi.ownershipType = transaction.ownershipType
        
        return esi
    }
    
    /// 与产品订阅相关的文本，格式为订阅、已订阅、x天后续订等
    /// - Returns: 返回与产品订阅相关的文本
    @MainActor public func shortInfo() async -> String {
        
        var text = ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        
        if let state = subscriptionInfo.subscriptionStatus?.state {
            switch state {
                case .subscribed: text += "已订阅"
                case .inGracePeriod: text += "已订阅。即将过期"
                case .inBillingRetryPeriod: text += "已订阅。续订失败"
                case .revoked: text += "订阅已撤销"
                case .expired: text += "订阅已过期"
                default: text += "订阅状态未知"
            }
        }
        
        if let latestTransaction = subscriptionInfo.latestVerifiedTransaction,
           let renewalDate = latestTransaction.expirationDate {
            
            if latestTransaction.isUpgraded { text += " 已升级" }
            else  {
                
                let diffComponents = Calendar.current.dateComponents([.day], from: Date(), to: renewalDate)
                if let daysLeft = diffComponents.day {
                    if daysLeft >= 1 { text += " 在 \(daysLeft) 天后续订" }
                    else { text += " 今天续订" }
                }
            }
        }
        
        return text
    }
}
