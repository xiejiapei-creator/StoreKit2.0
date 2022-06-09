//
//  SubscriptionView.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/5.
//
// 视图层次：SubscriptionView
// Subscriptions:   [Products].[ProductListView].[SubscriptionListViewRow].[SubscriptionView].[if purchased].[SubscriptionInfoView].[SubscriptionInfoSheet]

import SwiftUI

/// 订阅产品视图
@available(tvOS 15.0, *)
public struct SubscriptionView: View {
    @EnvironmentObject var storeHelper: StoreHelper
    @State var purchaseState: PurchaseState = .unknown
    var productId: ProductId
    var displayName: String
    var description: String
    var price: String
    var subscriptionInfo: SubscriptionInfo?  // 如果非nil，则该产品是用户在订阅组中订阅的最高服务级别产品
    var productInfoCompletion: ((ProductId) -> Void)
    
    public var body: some View {
        VStack {
            LargeTitleFont(scaleFactor: storeHelper.fontScaleFactor) { Text(displayName)}.padding(.bottom, 1)
            #if os(iOS)
            SubHeadlineFont(scaleFactor: storeHelper.fontScaleFactor) { Text(description)}
                .padding(EdgeInsets(top: 0, leading: 5, bottom: 3, trailing: 5))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .contentShape(Rectangle())
                .onTapGesture { productInfoCompletion(productId) }
            #elseif os(macOS)
            BodyFont(scaleFactor: storeHelper.fontScaleFactor) { Text(description)}
                .padding(EdgeInsets(top: 0, leading: 5, bottom: 3, trailing: 5))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .contentShape(Rectangle())
                .onTapGesture { productInfoCompletion(productId) }
            #endif

            HStack {
                Image(productId)
                    .resizable()
                    .frame(maxWidth: 250, maxHeight: 250)
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(25)
                    .contentShape(Rectangle())
                    #if !os(tvOS)
                    .onTapGesture { productInfoCompletion(productId) }
                    #endif
                
                Spacer()
                PurchaseButton(purchaseState: $purchaseState, productId: productId, price: price)
            }
            #if os(macOS)
            .frame(width: 500)
            #endif
            .padding()
            
            if purchaseState == .purchased, subscriptionInfo != nil {
                SubscriptionInfoView(subscriptionInfo: subscriptionInfo!)
            } else {
                ProductInfoView(productId: productId, displayName: displayName, productInfoCompletion: productInfoCompletion)
            }
            
            Divider()
        }
        .padding()
        .task { await purchaseState(for: productId)}
        .onChange(of: storeHelper.purchasedProducts) { _ in
            Task.init { await purchaseState(for: productId) }
        }
    }
    
    func purchaseState(for productId: ProductId) async {
        let purchased = (try? await storeHelper.isPurchased(productId: productId)) ?? false
        purchaseState = purchased ? .purchased : .unknown
    }
}
