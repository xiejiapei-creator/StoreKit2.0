//
//  SubscriptionListViewRow.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/5.
//
// 视图层次：SubscriptionListViewRow
// Subscriptions:   [Products].[ProductListView].[SubscriptionListViewRow].[SubscriptionView].[if purchased].[SubscriptionInfoView].[SubscriptionInfoSheet]

import SwiftUI
import StoreKit
import OrderedCollections

/// 订阅列表
@available(tvOS 15.0, *)
public struct SubscriptionListViewRow: View {
    @EnvironmentObject var storeHelper: StoreHelper
    @State private var subscriptionGroups: OrderedSet<String>?
    @State private var subscriptionInfo: OrderedSet<SubscriptionInfo>?
    
    var products: [Product]
    var headerText: String
    var productInfoCompletion: ((ProductId) -> Void)
    
    public var body: some View {
        Section(header: Text(headerText)) {
            // 对于组中的每个产品，使用SubscriptionView（）显示为一行
            // 如果产品是最高订阅级别，则将其SubscriptionInfo传递给SubscriptionView（）
            ForEach(products, id: \.id) { product in
                SubscriptionView(productId: product.id,
                                 displayName: product.displayName,
                                 description: product.description,
                                 price: product.displayPrice,
                                 subscriptionInfo: storeHelper.subscriptionHelper.subscriptionInformation(for: product, in: subscriptionInfo),
                                 productInfoCompletion: productInfoCompletion)
                    .contentShape(Rectangle())
                    #if !os(tvOS)
                    .onTapGesture { productInfoCompletion(product.id) }
                    #endif
            }
        }
        .task { subscriptionInfo = await storeHelper.subscriptionHelper.groupSubscriptionInfo()}
        .onChange(of: storeHelper.purchasedProducts) { _ in
            Task.init { subscriptionInfo = await storeHelper.subscriptionHelper.groupSubscriptionInfo()}
        }
    }
}
