//
//  LFTProductView.swift
//  StoreHelperDemo
//
//  Created by 谢佳培 on 2022/6/5.
//

import SwiftUI
import StoreKit

/// 首页产品视图
struct LFTProductView: View {
    @EnvironmentObject var storeHelper: StoreHelper
    @State private var isPurchased = false
    var productId: ProductId
    
    var body: some View {
        VStack {
            if isPurchased {
                Image(productId).bodyImage()
                Text("您已购买此产品并具有完全访问权限 😁").font(.title).foregroundColor(.green)
            } else {
                Text("抱歉，您尚未购买此产品，没有访问权限 😞").font(.title).foregroundColor(.red)
            }
        }
        .padding()
        .task {
            if let purchased = try? await storeHelper.isPurchased(productId: productId) {
                isPurchased = purchased
                print("StoreKit1 收据在这里: \(Bundle.main.appStoreReceiptURL!)")
            }
        }
    }
}

