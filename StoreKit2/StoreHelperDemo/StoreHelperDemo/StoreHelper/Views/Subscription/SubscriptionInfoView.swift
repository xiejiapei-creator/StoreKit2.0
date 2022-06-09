//
//  SubscriptionInfoView.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/5.
//
// 视图层次：SubscriptionInfoView
// Subscriptions:   [Products].[ProductListView].[SubscriptionListViewRow].[SubscriptionView].[if purchased].[SubscriptionInfoView].[SubscriptionInfoSheet]

import SwiftUI
import StoreKit

/// 订阅产品详情视图
@available(tvOS 15.0, *)
public struct SubscriptionInfoView: View {
    @EnvironmentObject var storeHelper: StoreHelper
    @State var subscriptionInfoText = ""
    @State private var showSubscriptionInfoSheet = false
    var subscriptionInfo: SubscriptionInfo  // 由家长设置
    
    public var body: some View {
        
        let viewModel = SubscriptionInfoViewModel(storeHelper: storeHelper, subscriptionInfo: subscriptionInfo)
        
        #if os(iOS)
        HStack(alignment: .center) {
            Button(action: { withAnimation { showSubscriptionInfoSheet.toggle()}}) {
                HStack {
                    Image(systemName: "creditcard.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 30)
                    
                    SubHeadlineFont(scaleFactor: storeHelper.fontScaleFactor) { Text(subscriptionInfoText)}
                        .foregroundColor(.blue)
                        .lineLimit(nil)
                }
                .padding()
            }
        }
        .task { subscriptionInfoText = await viewModel.shortInfo()}
        .sheet(isPresented: $showSubscriptionInfoSheet) {
            if let pid = subscriptionInfo.product?.id {
                SubscriptionInfoSheet(showPurchaseInfoSheet: $showSubscriptionInfoSheet, productId: pid, viewModel: viewModel)
            }
        }
        #elseif os(macOS)
        HStack(alignment: .center) {
            Image(systemName: "creditcard.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.blue)
                .frame(height: 30)

            Title3Font(scaleFactor: storeHelper.fontScaleFactor) { Text(subscriptionInfoText)}
                .foregroundColor(.blue)
                .lineLimit(nil)
        }
        .padding()
        .onTapGesture { withAnimation { showSubscriptionInfoSheet.toggle()}}
        .task { subscriptionInfoText = await viewModel.shortInfo()}
        .sheet(isPresented: $showSubscriptionInfoSheet) {
            if let pid = subscriptionInfo.product?.id {
                SubscriptionInfoSheet(showPurchaseInfoSheet: $showSubscriptionInfoSheet, productId: pid, viewModel: viewModel)
            }
        }
        #endif
    }
}

