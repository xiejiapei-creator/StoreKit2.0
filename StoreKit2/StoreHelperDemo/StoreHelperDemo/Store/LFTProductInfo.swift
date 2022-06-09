//
//  LFTProductPurchaseInfo.swift
//  StoreHelperDemo
//
//  Created by 谢佳培 on 2022/6/5.
//

import SwiftUI
import StoreKit

/// 列表产品详情视图
struct LFTProductInfo: View {
    @EnvironmentObject var storeHelper: StoreHelper
    @State private var product: Product?
    @Binding var productInfoProductId: ProductId
    @Binding var showProductInfoSheet: Bool
    
    var body: some View {
        VStack {
            SheetBarView(showSheet: $showProductInfoSheet, title: product?.displayName ?? "产品信息")
            ScrollView {
                VStack {
                    if let p = product {
                        Image(p.id)
                            .resizable()
                            .frame(maxWidth: 200, maxHeight: 200)
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(25)
                    }
                    
                    // 输入适合产品的文本
                    switch productInfoProductId {
                        case "com.nonconsumable.flowers.large": ProductInfoFlowersLarge()
                        case "com.nonconsumable.flowers.small": ProductInfoFlowersSmall()
                        default: ProductInfoDefault()
                    }
                }
                .padding(.bottom)
            }
        }
        .onAppear {
            product = storeHelper.product(from: productInfoProductId)
        }
    }
}

struct ProductInfoFlowersLarge: View {
    @ViewBuilder var body: some View {
        Text("鲜花向日葵配6朵香槟玫瑰花束").font(.title2).padding().multilineTextAlignment(.center)
        Text("向日葵花语是信念、光辉、高傲、忠诚、爱慕，它的寓意是沉默的爱，向日葵代表着勇敢地去追求自己想要的幸福。向日葵的花姿虽然没有玫瑰那么浪漫，没有百合那么纯净，但它阳光、明亮，爱得坦坦荡荡，爱得不离不弃，有着属于自己的独特魅力。").font(.title3).padding().multilineTextAlignment(.center)
    }
}

struct ProductInfoFlowersSmall: View {
    @ViewBuilder var body: some View {
        Text("11朵满天星甘菊混搭花束").font(.title2).padding().multilineTextAlignment(.center)
        Text("寓意着对某个人或者某段感情的怀念").font(.title3).padding().multilineTextAlignment(.center)
    }
}

struct ProductInfoDefault: View {
    @ViewBuilder var body: some View {
        Text("普通花朵").font(.title2).padding().multilineTextAlignment(.center)
        Text("快买朵花吧，可以把它送给自己喜欢的人").font(.title3).padding().multilineTextAlignment(.center)
    }
}
