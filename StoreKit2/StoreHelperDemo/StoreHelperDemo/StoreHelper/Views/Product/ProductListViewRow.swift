//
//  ProductListViewRow.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/5.
//
// Non-Consumables: [Products].[ProductListView].[ProductListViewRow]......[ProductView]......[if purchased].[PurchaseInfoView].....[PurchaseInfoSheet]

import SwiftUI
import StoreKit

/// 产品列表Item视图
@available(tvOS 15.0, *)
public struct ProductListViewRow: View {
    @EnvironmentObject var storeHelper: StoreHelper
    #if os(iOS)
    @Binding var showRefundSheet: Bool
    @Binding var refundRequestTransactionId: UInt64
    #endif

    var products: [Product]
    var headerText: String
    var productInfoCompletion: ((ProductId) -> Void)
    
    public var body: some View {
        Section(content: {
            if let p = products.first {
                if p.type == .consumable {// 展示消耗品
                    ForEach(products, id: \.id) { product in
                        ConsumableView(productId: product.id,
                                       displayName: product.displayName,
                                       description: product.description,
                                       price: product.displayPrice,
                                       productInfoCompletion: productInfoCompletion)
                        .contentShape(Rectangle())
                        #if !os(tvOS)
                        .onTapGesture { productInfoCompletion(product.id)}
                        #endif
                    }
                } else {// 展示其他产品
                    ForEach(products, id: \.id) { product in
                        #if os(iOS)
                        ProductView(showRefundSheet: $showRefundSheet,
                                    refundRequestTransactionId: $refundRequestTransactionId,
                                    productId: product.id,
                                    displayName: product.displayName,
                                    description: product.description,
                                    price: product.displayPrice,
                                    productInfoCompletion: productInfoCompletion)
                        .contentShape(Rectangle())
                        .onTapGesture { productInfoCompletion(product.id) }
                        #elseif os(macOS)
                        ProductView(productId: product.id,
                                    displayName: product.displayName,
                                    description: product.description,
                                    price: product.displayPrice,
                                    productInfoCompletion: productInfoCompletion)
                        .contentShape(Rectangle())
                        .onTapGesture { productInfoCompletion(product.id) }
                        #elseif os(tvOS)
                        ProductView(productId: product.id,
                                    displayName: product.displayName,
                                    description: product.description,
                                    price: product.displayPrice,
                                    productInfoCompletion: productInfoCompletion)
                        .contentShape(Rectangle())
                        #endif
                    }
                }
            }
        }, header: { BodyFont(scaleFactor: storeHelper.fontScaleFactor) { Text(headerText)}})
    }
}

