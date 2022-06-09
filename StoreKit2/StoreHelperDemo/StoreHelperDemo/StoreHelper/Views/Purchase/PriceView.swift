//
//  PriceView.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/5.
//

import SwiftUI
import StoreKit

/// 显示产品价格和允许购买的按钮
@available(tvOS 15.0, *)
public struct PriceView: View {
    @EnvironmentObject var storeHelper: StoreHelper
    @State private var canMakePayments: Bool = false
    @Binding var purchaseState: PurchaseState  // 从PriceViewModel传回购买结果
    
    var productId: ProductId
    var price: String
    var product: Product
    
    public var body: some View {
        
        let priceViewModel = PriceViewModel(storeHelper: storeHelper, purchaseState: $purchaseState)
        
        HStack {
            
            #if os(iOS)
            Button(action: {
                withAnimation { purchaseState = .inProgress }
                Task.init { await priceViewModel.purchase(product: product) }
            }) {
                PriceButtonText(price: price, disabled: !canMakePayments)
            }
            .disabled(!canMakePayments)
            #elseif os(macOS)
            HStack { PriceButtonText(price: price, disabled: !canMakePayments)}
            .contentShape(Rectangle())
            .onTapGesture {
                guard canMakePayments else { return }
                withAnimation { purchaseState = .inProgress }
                Task.init { await priceViewModel.purchase(product: product) }
            }
            #endif
        }
        .onAppear { canMakePayments = AppStore.canMakePayments }
    }
}

/// 价格按钮
@available(tvOS 15.0, *)
public struct PriceButtonText: View {
    #if os(iOS)
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    #endif
    
    @EnvironmentObject var storeHelper: StoreHelper
    var price: String
    var disabled: Bool
    
    public var body: some View {
        Text(disabled ? "不能使用" : price)  // 不要在价格上使用缩放字体，因为这样会导致截短
            .font(.body)
            .foregroundColor(.white)
            .padding()
            #if os(iOS)
            .frame(height: 40)
            #elseif os(macOS)
            .frame(height: 40)
            #endif
            .fixedSize()
            .background(Color.blue)
            .cornerRadius(25)
    }
}

@available(tvOS 15.0, *)
struct PriceView_Previews: PreviewProvider {

    static var previews: some View {
        HStack {
            Button(action: {}) {
                Text("USD $1.98")
                    .font(.body)
                    .foregroundColor(.white)
                    .padding()
                    .frame(height: 40)
                    .padding(.leading, 0)
                    .fixedSize()
                    .background(Color.blue)
                    .cornerRadius(25)
            }
        }
        .padding()
    }
}

