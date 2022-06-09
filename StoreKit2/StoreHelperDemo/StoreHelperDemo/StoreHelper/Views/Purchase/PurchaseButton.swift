//
//  PurchaseButton.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/5.
//

import SwiftUI
import StoreKit

/// 提供允许用户购买产品的按钮
/// 产品价格也以当地货币显示
@available(tvOS 15.0, *)
public struct PurchaseButton: View {
    
    @EnvironmentObject var storeHelper: StoreHelper
    @Binding var purchaseState: PurchaseState
    
    var productId: ProductId
    var price: String
    
    public var body: some View {
        
        let product = storeHelper.product(from: productId)
        if product == nil {
            
            StoreErrorView()
            
        } else {
            
            HStack {
                
                if product!.type == .consumable {// 消耗品
                    
                    if purchaseState != .purchased { withAnimation { BadgeView(purchaseState: $purchaseState) }}
                    PriceView(purchaseState: $purchaseState, productId: productId, price: price, product: product!)
                    
                } else {
                    
                    withAnimation { BadgeView(purchaseState: $purchaseState) }
                    if purchaseState != .purchased { PriceView(purchaseState: $purchaseState, productId: productId, price: price, product: product!) }
                }
            }
        }
    }
}

/// 购买按钮
@available(tvOS 15.0, *)
struct PurchaseButton_Previews: PreviewProvider {
    static var previews: some View {

        @StateObject var storeHelper = StoreHelper()
        @State var purchaseState: PurchaseState = .inProgress

        return PurchaseButton(purchaseState: $purchaseState,
                              productId: "nonconsumable.flowers-large",
                              price: "£1.99")
            .environmentObject(storeHelper)
    }
}
