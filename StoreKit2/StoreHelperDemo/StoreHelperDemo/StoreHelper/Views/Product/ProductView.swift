//
//  ProductView.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/5.
//
// Non-Consumables: [Products].[ProductListView].[ProductListViewRow]......[ProductView]......[if purchased].[PurchaseInfoView].....[PurchaseInfoSheet]

import SwiftUI
import StoreKit

#if !os(tvOS)
import WidgetKit
#endif

/// 显示主内容列表的单行产品信息
@available(tvOS 15.0, *)
public struct ProductView: View {
    @EnvironmentObject var storeHelper: StoreHelper
    @State var purchaseState: PurchaseState = .unknown
    #if os(iOS)
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Binding var showRefundSheet: Bool
    @Binding var refundRequestTransactionId: UInt64
    #endif
    
    var productId: ProductId
    var displayName: String
    var description: String
    var price: String
    var productInfoCompletion: ((ProductId) -> Void)
    
    public var body: some View {
        VStack {
            LargeTitleFont(scaleFactor: storeHelper.fontScaleFactor) { Text(displayName)}.padding(.bottom, 1)
            #if os(iOS)
            SubHeadlineFont(scaleFactor: storeHelper.fontScaleFactor) { Text(description)}
                .padding(EdgeInsets(top: 0, leading: 5, bottom: 3, trailing: 5))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .contentShape(Rectangle())
                .onTapGesture { productInfoCompletion(productId) }
            #elseif os(macOS)
            Text(description)
                .padding(EdgeInsets(top: 0, leading: 5, bottom: 3, trailing: 5))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .contentShape(Rectangle())
                .onTapGesture { productInfoCompletion(productId) }
            #elseif os(tvOS)
            Text(description)
                .padding(EdgeInsets(top: 0, leading: 5, bottom: 3, trailing: 5))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .contentShape(Rectangle())
            #endif
            
            #if os(iOS)
            if horizontalSizeClass == .compact {
                VStack {
                    Image(productId)
                        .resizable()
                        .frame(maxWidth: 250, maxHeight: 250)
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(25)
                        .contentShape(Rectangle())
                        .onTapGesture { productInfoCompletion(productId) }
                    
                    PurchaseButton(purchaseState: $purchaseState, productId: productId, price: price)
                }
                .padding()
            } else {
                HStack {
                    Image(productId)
                        .resizable()
                        .frame(maxWidth: 250, maxHeight: 250)
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(25)
                        .contentShape(Rectangle())
                        .onTapGesture { productInfoCompletion(productId) }
                    
                    Spacer()
                    PurchaseButton(purchaseState: $purchaseState, productId: productId, price: price)
                }
                .padding()
            }
            #else
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
            .frame(width: 500)
            .padding()
            #endif
            
            if purchaseState == .purchased {
                #if os(iOS)
                PurchaseInfoView(showRefundSheet: $showRefundSheet, refundRequestTransactionId: $refundRequestTransactionId, productId: productId)
                #else
                PurchaseInfoView(productId: productId)
                #endif
            }
            else {
                ProductInfoView(productId: productId, displayName: displayName, productInfoCompletion: productInfoCompletion)
            }
            
            Divider()
        }
        .padding()
        .task { await purchaseState(for: productId)}
        .onChange(of: storeHelper.purchasedProducts) { _ in
            Task.init {
                await purchaseState(for: productId)
                #if !os(tvOS)
                WidgetCenter.shared.reloadAllTimelines()
                #endif
            }
        }
    }
    
    func purchaseState(for productId: ProductId) async {
        let purchased = (try? await storeHelper.isPurchased(productId: productId)) ?? false
        purchaseState = purchased ? .purchased : .unknown
    }
}

