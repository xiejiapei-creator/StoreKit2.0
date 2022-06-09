//
//  ProductListView.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/5.
//
// Non-Consumables: [Products].[ProductListView].[ProductListViewRow]......[ProductView]......[if purchased].[PurchaseInfoView].....[PurchaseInfoSheet]

import SwiftUI

/// 产品列表
@available(tvOS 15.0, *)
public struct ProductListView: View {
    @EnvironmentObject var storeHelper: StoreHelper
    #if os(iOS)
    @Binding var showRefundSheet: Bool
    @Binding var refundRequestTransactionId: UInt64
    #endif
    
    var productInfoCompletion: ((ProductId) -> Void)
    
    public var body: some View {
        
        if storeHelper.hasProducts {
    
            if storeHelper.hasNonConsumableProducts, let nonConsumables = storeHelper.nonConsumableProducts {
                #if os(iOS)
                ProductListViewRow(showRefundSheet: $showRefundSheet, refundRequestTransactionId: $refundRequestTransactionId, products: nonConsumables, headerText: "非消耗性产品列表", productInfoCompletion: productInfoCompletion)
                #else
                ProductListViewRow(products: nonConsumables, headerText: "非消耗性产品列表", productInfoCompletion: productInfoCompletion)
                #endif
            }
            
            if storeHelper.hasConsumableProducts, let consumables = storeHelper.consumableProducts {
                #if os(iOS)
                ProductListViewRow(showRefundSheet: $showRefundSheet, refundRequestTransactionId: $refundRequestTransactionId, products: consumables, headerText: "消耗性产品列表", productInfoCompletion: productInfoCompletion)
                #else
                ProductListViewRow(products: consumables, headerText: "消耗性产品列表", productInfoCompletion: productInfoCompletion)
                #endif
            }
            
            if storeHelper.hasSubscriptionProducts, let subscriptions = storeHelper.subscriptionProducts {
                SubscriptionListViewRow(products: subscriptions, headerText: "订阅VIP服务", productInfoCompletion: productInfoCompletion)
            }
            
        } else {
            
            VStack {
                TitleFont(scaleFactor: storeHelper.fontScaleFactor) { Text("无可用产品")}.foregroundColor(.red)
                
                CaptionFont(scaleFactor: storeHelper.fontScaleFactor) { Text("此错误表示与应用商店的连接暂时不可用。您以前购买的物品可能无法使用。\n\n请检查网络连接，然后重试。")}
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button(action: { storeHelper.refreshProductsFromAppStore()}) {
                    BodyFont(scaleFactor: storeHelper.fontScaleFactor) { Text("重试应用商店")}
                }
                #if os(iOS)
                .buttonStyle(.borderedProminent).padding()
                #elseif os(macOS)
                .macOSStyle()
                #endif
                
                Divider()
            }
        }
    }
}
