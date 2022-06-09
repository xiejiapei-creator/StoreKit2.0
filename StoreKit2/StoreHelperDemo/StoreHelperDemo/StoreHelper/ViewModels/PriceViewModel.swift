//
//  PriceViewModel.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/9.
//

import StoreKit
import SwiftUI

/// PriceView 的视图模型，支持购买
@available(tvOS 15.0, *)
public struct PriceViewModel {
    @ObservedObject public var storeHelper: StoreHelper
    @Binding public var purchaseState: PurchaseState
    
    public init(storeHelper: StoreHelper, purchaseState: Binding<PurchaseState>) {
        self.storeHelper = storeHelper
        self._purchaseState = purchaseState
    }
    
    /// 使用StoreHelper和StoreKit2购买产品
    /// - Parameter product: 要购买的产品
    @MainActor public func purchase(product: Product) async {
        do {
            let purchaseResult = try await storeHelper.purchase(product)
            withAnimation { purchaseState = purchaseResult.purchaseState }
        } catch { purchaseState = .failed }  // 购买失败或验证失败
    }
}
