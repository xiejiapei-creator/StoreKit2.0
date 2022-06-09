//
//  PurchaseInfoViewModel.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/9.
//

import StoreKit
import SwiftUI

/// 提供有关购买非消耗品的扩展信息
@available(tvOS 15.0, *)
public struct ExtendedPurchaseInfo: Hashable {
    public var productId: ProductId                                      // 产品的唯一id
    public var name: String                                              // 产品的显示名称
    public var isPurchased: Bool                                         // 如果已购买产品，则为true
    public var productType: Product.ProductType                          // 消耗品、非消耗品、订阅等
    public var transactionId: UInt64?                                    // 购买的transactionid。UInt64.min（如果未购买）
    public var purchasePrice: String?                                    // 购买时支付的本地化价格
    public var purchaseDate: Date?                                       // 购买日期
    public var purchaseDateFormatted: String?                            // 购买日期格式为“yyyyMMMdd”（例如“2021年12月28日”）
    public var revocationDate: Date?                                     // 应用程序撤销购买的日期（例如，由于退款等原因）
    public var revocationDateFormatted: String?                          // 撤销日期格式为“yyyyMMMdd”
    public var revocationReason: StoreKit.Transaction.RevocationReason?  // 取消购买的原因
    public var ownershipType: StoreKit.Transaction.OwnershipType?        // 私人购买或者家庭购买

    public init(productId: ProductId,
                name: String,
                isPurchased: Bool,
                productType: Product.ProductType,
                transactionId: UInt64?  = nil,
                purchasePrice: String? = nil,
                purchaseDate: Date? = nil,
                purchaseDateFormatted: String? = nil,
                revocationDate: Date? = nil,
                revocationDateFormatted: String? = nil,
                revocationReason: StoreKit.Transaction.RevocationReason? = nil,
                ownershipType: StoreKit.Transaction.OwnershipType? = nil) {
        
        self.productId = productId
        self.name = name
        self.isPurchased = isPurchased
        self.productType = productType
        self.transactionId = transactionId
        self.purchasePrice = purchasePrice
        self.purchaseDate = purchaseDate
        self.purchaseDateFormatted = purchaseDateFormatted
        self.revocationDate = revocationDate
        self.revocationDateFormatted = revocationDateFormatted
        self.revocationReason = revocationReason
        self.ownershipType = ownershipType
    }
}

/// PurchaseInfoView 的视图模型，支持收集购买或订阅信息
@available(tvOS 15.0, *)
public struct PurchaseInfoViewModel {
    
    @ObservedObject public var storeHelper: StoreHelper
    public var productId: ProductId
    
    /// 提供有关购买非消耗品或自动续订订阅的文本信息
    /// - Parameter productId: 产品或订阅的 ProductId
    /// - Returns: 返回有关购买非消耗性产品或自动续订订阅的文本信息
    @MainActor public func info(for productId: ProductId) async -> String {
        
        guard let product = storeHelper.product(from: productId) else { return "没有可用的购买信息" }
        guard product.type != .nonRenewable else { return "没有不可续费订阅的信息" }
        
        // 我们是在处理消耗品吗？如果是这样的话，我们唯一的数据就是是否购买了该产品
        // 目前，StoreHelper只需对购买的每种特定消费品进行计数
        // 我们不会将购买日期等存储在支持您的消费品的生产系统中
        // 请注意，StoreKit不会在收据中存储消耗品购买的数据。
        if product.type == .consumable {
            if let consumablePurchased = try? await storeHelper.isPurchased(product: product) {
                return consumablePurchased ? "已购买" : "未购买"
            }
            
            return "无采购数据"
        }
        
        // 我们正在处理非消耗品或订阅
        // 获取产品的详细购买/订阅信息
        guard let info = await storeHelper.purchaseInfo(for: product) else { return "" }
        
        var text = ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        
        // 如果StoreKit2验证了交易，那么我们可以访问购买日期
        if info.product.type == .nonConsumable {
            guard let transaction = info.latestVerifiedTransaction else { return "" }
            
            text = "产品购买于 \(dateFormatter.string(from: transaction.purchaseDate))"
            if let revocationDate = transaction.revocationDate {
                text += " (产品撤销于 \(dateFormatter.string(from: revocationDate)))"
            }
        }
        
        return text
    }
    
    /// 提供有关购买非消耗品的扩展信息
    /// - Parameter productId: 产品或订阅的 ProductId
    /// - Returns: 在购买非消耗品或自动续订订阅时返回 ProductPurchaseInfo ，未购买任何产品则返回nil
    @MainActor public func extendedPurchaseInfo(for nonConsumableProductId: ProductId) async -> ExtendedPurchaseInfo? {
        guard let product = storeHelper.product(from: productId) else { return nil }
        
        var epi =  ExtendedPurchaseInfo(productId: product.id, name: product.displayName, isPurchased: false, productType: product.type, purchasePrice: product.displayPrice)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        
        epi.isPurchased = (try? await storeHelper.isPurchased(productId: product.id)) ?? false
        guard epi.isPurchased else { return epi }
        guard let transaction = await storeHelper.mostRecentTransaction(for: product.id) else { return epi }

        epi.transactionId = transaction.id
        epi.purchaseDate = transaction.purchaseDate
        epi.purchaseDateFormatted = dateFormatter.string(from: transaction.purchaseDate)
        epi.revocationDate = transaction.revocationDate
        epi.revocationDateFormatted = transaction.revocationDate == nil ? nil : dateFormatter.string(from: transaction.revocationDate!)
        epi.revocationReason = transaction.revocationReason
        epi.ownershipType = transaction.ownershipType
        
        return epi
    }
    
    /// 确定以前是否购买过产品。适用于所有产品类型（消耗品、非消耗品和订阅）
    /// - Parameter productId: 产品的 ProductId
    /// - Returns: 如果产品已购买，则返回true，否则返回false
    @MainActor public func isPurchased(productId: ProductId) async -> Bool { (try? await storeHelper.isPurchased(productId: productId)) ?? false }
}

