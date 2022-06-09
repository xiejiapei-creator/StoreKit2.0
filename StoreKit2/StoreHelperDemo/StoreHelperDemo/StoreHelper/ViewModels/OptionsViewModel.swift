//
//  OptionsViewModel.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/9.
//

import SwiftUI
import StoreKit

/// 可选的的视图模型，支持重置与恢复购买
@available(tvOS 15.0, *)
public struct OptionsViewModel {
    @ObservedObject public var storeHelper: StoreHelper
    
    public init(storeHelper: StoreHelper){
        self.storeHelper = storeHelper
    }
    
    #if DEBUG
    /// 重置（删除）钥匙链中的所有已购买的消耗品。仅调试示例
    public func resetConsumables() {
        guard storeHelper.hasConsumableProducts,
              let products = storeHelper.consumableProducts,
              let removedProducts = KeychainHelper.resetKeychainConsumables(for: products.map { $0.id }) else { return }
        
        Task.init {
            for product in removedProducts { await storeHelper.updatePurchasedIdentifiers(product, insert: false) }
        }
    }
    #endif
    
    /// 恢复以前的用户购买。对于StoreKit2，这通常是不必要的，只应在响应显式用户操作时执行。将导致用户必须使用App Store进行身份验证
    public func restorePurchases() {
        Task.init { try? await AppStore.sync() }
    }
}
