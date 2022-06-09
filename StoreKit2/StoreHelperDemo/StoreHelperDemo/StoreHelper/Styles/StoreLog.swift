//
//  StoreLog.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/8.
//

import Foundation
import os.log

/// 我们使用苹果的统一日志系统来记录错误、通知和一般消息
@available(tvOS 15.0, *)
public struct StoreLog {
    private static let storeLog = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "STORE")
    
    /// 记录StoreNotification
    /// 请注意，日志条目的文本（简短描述）将在控制台应用程序中公开提供
    /// - Parameter event: StoreNotification
    public static func event(_ event: StoreNotification) {
        #if DEBUG
        print(event.shortDescription())
        #else
        os_log("%{public}s", log: storeLog, type: .default, event.shortDescription())
        #endif
    }
    
    /// 公开提供 ProductId
    /// - Parameters:
    ///   - event:      StoreNotification.
    ///   - productId:  与事件关联的ProductId
    public static func event(_ event: StoreNotification, productId: ProductId) {
        #if DEBUG
        print("\(event.shortDescription()) for product \(productId)")
        #else
        os_log("%{public}s for product %{public}s", log: storeLog, type: .default, event.shortDescription(), productId)
        #endif
    }
    
    /// 公开提供 ProductId
    /// - Parameters:
    ///   - event:      StoreNotification.
    ///   - productId:  与事件关联的ProductId
    ///   - webOrderLineItemId: 标识跨设备的订阅购买事件（包括订阅续订）的唯一ID
    public static func event(_ event: StoreNotification, productId: ProductId, webOrderLineItemId: String?) {
        #if DEBUG
        print("\(event.shortDescription()) for product \(productId) with webOrderLineItemId \(webOrderLineItemId ?? "none")")
        #else
        os_log("%{public}s for product %{public}s with webOrderLineItemId %{public}s",
               log: storeLog,
               type: .default,
               event.shortDescription(),
               productId,
               webOrderLineItemId ?? "none")
        #endif
    }
    
    public static var transactionLog: Set<TransactionLog> = []
    
    /// 将StoreNotification记录为事务。同一事件和产品id的多个事务将只记录一次
    /// - Parameters:
    ///   - event:      StoreNotification.
    ///   - productId:  与事件关联的ProductId
    public static func transaction(_ event: StoreNotification, productId: ProductId) {
        
        let t = TransactionLog(notification: event, productId: productId)
        if transactionLog.contains(t) { return }
        transactionLog.insert(t)
        
        #if DEBUG
        print("\(event.shortDescription()) for product \(productId)")
        #else
        os_log("%{public}s for product %{public}s", log: storeLog, type: .default, event.shortDescription(), productId)
        #endif
    }
    
    /// 公开提供 ProductId
    /// - Parameters:
    ///   - exception:  StoreException.
    ///   - productId:  与事件关联的ProductId
    public static func exception(_ exception: StoreException, productId: ProductId) {
        #if DEBUG
        print("\(exception.shortDescription()). For product \(productId)")
        #else
        os_log("%{public}s for product %{public}s", log: storeLog, type: .default, exception.shortDescription(), productId)
        #endif
    }
    
    /// 记录消息
    /// - Parameter message: 要记录的消息
    public static func event(_ message: String) {
        #if DEBUG
        print(message)
        #else
        os_log("%s", log: storeLog, type: .info, message)
        #endif
    }
}

public struct TransactionLog: Hashable {
    
    let notification: StoreNotification
    let productId: ProductId
    
    public static func == (lhs: TransactionLog, rhs: TransactionLog) -> Bool {
        return (lhs.productId == rhs.productId) && (lhs.notification == rhs.notification)
    }
}

