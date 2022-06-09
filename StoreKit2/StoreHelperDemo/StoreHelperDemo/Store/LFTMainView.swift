//
//  LFTMainView.swift
//  StoreHelperDemo
//
//  Created by 谢佳培 on 2022/6/5.
//

import SwiftUI
import StoreKit

/// 首页视图
struct LFTMainView: View {
    let largeFlowersId = "com.nonconsumable.flowers.large"
    let smallFlowersId = "com.nonconsumable.flowers.small"
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: LFTContentView()) { Text("产品列表").font(.largeTitle).padding()}
                NavigationLink(destination: LFTProductView(productId: largeFlowersId)) { Text("已购买的向日葵").font(.largeTitle).padding()}
                NavigationLink(destination: LFTProductView(productId: smallFlowersId)) { Text("已购买的满天星").font(.largeTitle).padding()}
                NavigationLink(destination: LFTSubscriptionView()) { Text("已订阅的服务").font(.largeTitle).padding()}
            }
        }
        #if os(iOS)
        .navigationViewStyle(.stack)
        .navigationBarTitle(Text("StoreHelperDemo"), displayMode: .large)
        #endif
    }
}
