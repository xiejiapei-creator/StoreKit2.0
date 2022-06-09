//
//  ProductInfoView.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/5.
//
// Non-Consumables: [Products].[ProductListView].[ProductListViewRow]......[ProductView]......[if purchased].[PurchaseInfoView].....[PurchaseInfoSheet]

import SwiftUI

///
@available(tvOS 15.0, *)
public struct ProductInfoView: View {
    @EnvironmentObject var storeHelper: StoreHelper
    var productId: ProductId
    var displayName: String
    var productInfoCompletion: ((ProductId) -> Void)
    
    public var body: some View {
        #if os(iOS)
        Button(action: { productInfoCompletion(productId)}) {
            HStack {
                Image(systemName: "info.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 30)
                
                SubHeadlineFont(scaleFactor: storeHelper.fontScaleFactor) { Text("与\"\(displayName)\"有关的信息")}
                    .padding()
                    .foregroundColor(.blue)
                    .lineLimit(nil)
            }
            .padding()
        }
        #elseif os(macOS)
        HStack {
            Image(systemName: "info.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.blue)
                .frame(height: 30)
            
            Title3Font(scaleFactor: storeHelper.fontScaleFactor) { Text("与\"\(displayName)\"有关的信息")}
                .padding()
                .foregroundColor(.blue)
                .lineLimit(nil)
        }
        .padding()
        .onTapGesture { productInfoCompletion(productId)}
        #endif
    }
}

