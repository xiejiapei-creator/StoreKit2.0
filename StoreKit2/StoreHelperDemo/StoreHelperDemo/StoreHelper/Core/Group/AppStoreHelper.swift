//
//  AppStoreHelper.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/8.
//

import StoreKit

/// 支持StoreKit1。告诉观察者，用户直接从应用商店发起了应用内购买，而不是通过应用本身。StoreKit2（尚未）提供对该功能的支持，因此我们需要使用StoreKit1。这是在app Store上推广应用内购买的要求。如果您的应用程序没有实现 SKPaymentTransactionObserver 、 paymentQueue(_:updatedTransactions:)、 paymentQueue(_:shouldAddStorePayment:for:) 委托方法的类，则提交时会出现错误

/// 请注意，应用程序内生成的任何IAP都由StoreKit2处理，不涉及此helper类
@available(tvOS 15.0, *)
public class AppStoreHelper: NSObject, SKPaymentTransactionObserver {

    private weak var storeHelper: StoreHelper?
    
    public convenience init(storeHelper: StoreHelper) {
        self.init()
        self.storeHelper = storeHelper
    }
    
    public override init() {
        super.init()
        
        // 将我们添加为StoreKit付款队列的观察者
        // 这允许我们接收付款成功、失败、恢复等的通知。
        SKPaymentQueue.default().add(self)
    }
    
    /// StoreKit1付款队列的委托方法
    /// 请注意，因为我们的主要StoreKit处理是通过StoreHelper中的StoreKit2完成的
    /// 所以我们在这里所要做的就是向StoreKit1发出信号，以完成购买的、恢复的或失败的事务
    /// StoreKit1购买的物品可立即提供给StoreKit2（反之亦然）
    /// 因此任何购买物品都将由StoreHelper根据需要进行挑选
    /// - Parameters:
    ///   - queue: StoreKit1付款队列
    ///   - transactions: 收集更新的交易记录（例如已购买）
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
                case .purchased:
                    SKPaymentQueue.default().finishTransaction(transaction)
                    Task.init { await storeHelper?.productPurchased(transaction.payment.productIdentifier) }  // Tell StoreKit2-based StoreHelper about purchase
                case .restored: fallthrough
                case .failed: SKPaymentQueue.default().finishTransaction(transaction)
                default: break
            }
        }
    }
    
    /// 让我们知道用户直接从应用商店发起了应用内购买，而不是通过应用本身
    /// 如果您有IAP促销，则需要此方法
    public func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        // 返回true以继续事务。如果以前购买过此IAP，则StoreKit1将提取该IAP，并防止再次购买
        return true
    }
}
