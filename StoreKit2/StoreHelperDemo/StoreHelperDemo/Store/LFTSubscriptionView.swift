//
//  LFTSubscriptionView.swift
//  StoreHelperDemo
//
//  Created by 谢佳培 on 2022/6/5.
//

import SwiftUI
import StoreKit

struct LFTSubscriptionView: View {
    @EnvironmentObject var storeHelper: StoreHelper
    @State private var productIds: [ProductId]?
    
    var body: some View {
        VStack {
            if let pids = productIds {
                ForEach(pids, id: \.self) { pid in
                    LFTSubscriptionRow(productId: pid)
                    Divider()
                }
                
                Spacer()
            } else {
                Text("您没有任何订阅产品")
                    .font(.title)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .onAppear { productIds = storeHelper.subscriptionProductIds }
    }
}

struct LFTSubscriptionRow: View {
    @EnvironmentObject var storeHelper: StoreHelper
    @State private var isSubscribed = false
    @State private var detailedSubscriptionInfo: ExtendedSubscriptionInfo?
    var productId: ProductId
    
    var body: some View {
        VStack {
            HStack {
                Text("你 \(isSubscribed ? "已经" : "没有") 订阅  \(productId)")
                    .foregroundColor(isSubscribed ? .green : .red)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            if isSubscribed, let info = detailedSubscriptionInfo {
                Text("你的订阅产品： \(info.name) 在 \(info.renewsIn ?? "未知天数")后到期").multilineTextAlignment(.center)
                // 在此处显示更多订阅信息......
            }
        }
        .task {
            isSubscribed = await subscribed(to: productId)// 是否已经订阅
            if isSubscribed {
                if let subscriptionInfo = await getSubscriptionInfo() {// 订阅信息
                    detailedSubscriptionInfo = await getDetailedSubscriptionInfo(for: subscriptionInfo)// 订阅详情信息
                }
            }
        }
    }
    
    /// 判断是否订阅
    private func subscribed(to productId: ProductId) async -> Bool {
        let productPurchased = try? await storeHelper.isPurchased(productId: productId)
        return productPurchased ?? false
    }
    
    /// 获取订阅信息
    private func getSubscriptionInfo() async -> SubscriptionInfo? {
        var subInfo: SubscriptionInfo?
        
        // 获取所有订阅组的信息（此Demo只有一个名为VIP的组）
        let subscriptionGroupInfo = await storeHelper.subscriptionHelper.groupSubscriptionInfo()
        if let vipGroup = subscriptionGroupInfo?.first, let product = vipGroup.product {
            // 获取订阅产品的订阅信息
            subInfo = storeHelper.subscriptionHelper.subscriptionInformation(for: product, in: subscriptionGroupInfo)
        }
        
        return subInfo
    }
    
    /// 获取订阅详情信息
    private func getDetailedSubscriptionInfo(for subInfo: SubscriptionInfo) async -> ExtendedSubscriptionInfo? {
        let viewModel = SubscriptionInfoViewModel(storeHelper: storeHelper, subscriptionInfo: subInfo)
        return await viewModel.extendedSubscriptionInfo()// 扩展的订阅信息
    }
}
