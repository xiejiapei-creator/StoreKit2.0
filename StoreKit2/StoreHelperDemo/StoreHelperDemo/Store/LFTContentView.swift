//
//  LFTContentView.swift
//  StoreHelperDemo
//
//  Created by 谢佳培 on 2022/6/5.
//

import SwiftUI
import StoreKit

// 产品列表视图
struct LFTContentView: View {
    @State private var showProductInfoSheet = false
    @State private var productId: ProductId = ""
    
    var body: some View {
        ScrollView {
            Products() { id in
                productId = id
                showProductInfoSheet = true
            }
            .sheet(isPresented: $showProductInfoSheet) {// 弹出面板，解释由productId标识的特定产品的文本和图像
                VStack {
                    LFTProductInfo(productInfoProductId: $productId, showProductInfoSheet: $showProductInfoSheet)
                }
                #if os(macOS)
                .frame(minWidth: 500, idealWidth: 500, maxWidth: 500, minHeight: 500, idealHeight: 500, maxHeight: 500)
                #endif
            }
        }
    }
}
