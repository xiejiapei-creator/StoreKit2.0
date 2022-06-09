//
//  ConsumableView.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/5.
//
// Consumables:     [Products].[ProductListView].[ProductListViewRow]......[ConsumableView]...[if purchased].[PurchaseInfoView].....[PurchaseInfoSheet]

import SwiftUI
import StoreKit

#if !os(tvOS)
import WidgetKit
#endif

/// 消耗品视图
@available(tvOS 15.0, *)
public struct ConsumableView: View {
    @EnvironmentObject var storeHelper: StoreHelper
    @State var purchaseState: PurchaseState = .unknown
    @State var count: Int = 0
    
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
            BodyFont(scaleFactor: storeHelper.fontScaleFactor) { Text(description)}
                .padding(EdgeInsets(top: 0, leading: 5, bottom: 3, trailing: 5))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .contentShape(Rectangle())
                .onTapGesture { productInfoCompletion(productId) }
            #endif
            
            HStack {
                if count == 0 {
                    
                    Image(productId)
                        .resizable()
                        .frame(maxWidth: 250, maxHeight: 250)
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(25)
                        .contentShape(Rectangle())
                        #if !os(tvOS)
                        .onTapGesture { productInfoCompletion(productId) }
                        #endif
                    
                } else {
                    
                    Image(productId)
                        .resizable()
                        .frame(maxWidth: 250, maxHeight: 250)
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(25)
                        .overlay(ConsumableBadgeView(count: $count))
                        .contentShape(Rectangle())
                        #if !os(tvOS)
                        .onTapGesture { productInfoCompletion(productId) }
                        #endif
                }
                
                Spacer()
                PurchaseButton(purchaseState: $purchaseState, productId: productId, price: price)
            }
            #if os(macOS)
            .frame(width: 500)
            #endif
            .padding()

            if purchaseState == .purchased {
                #if os(iOS)
                PurchaseInfoView(showRefundSheet: .constant(false), refundRequestTransactionId: .constant(UInt64.min), productId: productId)
                #elseif os(macOS)
                PurchaseInfoView(productId: productId)
                #endif
            }
            else {
                ProductInfoView(productId: productId, displayName: displayName, productInfoCompletion: productInfoCompletion)
            }
            
            Divider()
        }
        .padding()
        .task {
            await purchaseState(for: productId)
            count = KeychainHelper.count(for: productId)
        }
        .onChange(of: storeHelper.purchasedProducts) { _ in
            Task.init { await purchaseState(for: productId) }
            count = KeychainHelper.count(for: productId)
            #if !os(tvOS)
            WidgetCenter.shared.reloadAllTimelines()
            #endif
        }
    }
    
    func purchaseState(for productId: ProductId) async {
        let purchased = (try? await storeHelper.isPurchased(productId: productId)) ?? false
        purchaseState = purchased ? .purchased : .unknown
    }
}

@available(tvOS 15.0, *)
struct ConsumableView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        @StateObject var storeHelper = StoreHelper()
        
        return ConsumableView(productId: "com.consumable.plant-installation",
                              displayName: "定制花束",
                              description: "按照你的要求，为你精心挑选花束",
                              price: "£0.99") { pid in }
            .environmentObject(storeHelper)
    }
}
