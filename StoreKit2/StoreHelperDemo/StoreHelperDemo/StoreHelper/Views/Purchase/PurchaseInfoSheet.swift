//
//  PurchaseInfoSheet.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/5.
//
// 视图层次: PurchaseInfoSheet
// Non-Consumables: [Products].[ProductListView].[ProductListViewRow]......[ProductView]......[if purchased].[PurchaseInfoView].....[PurchaseInfoSheet]
// Consumables:     [Products].[ProductListView].[ProductListViewRow]......[ConsumableView]...[if purchased].[PurchaseInfoView].....[PurchaseInfoSheet]
// Subscriptions:   [Products].[ProductListView].[SubscriptionListViewRow].[SubscriptionView].[if purchased].[SubscriptionInfoView].[SubscriptionInfoSheet]

import SwiftUI

@available(tvOS 15.0, *)
public struct PurchaseInfoSheet: View {
    @EnvironmentObject var storeHelper: StoreHelper
    @State private var extendedPurchaseInfo: ExtendedPurchaseInfo?
    @State private var showManagePurchase = false
    @Binding var showPurchaseInfoSheet: Bool
    #if os(iOS)
    @Binding var showRefundSheet: Bool
    @Binding var refundRequestTransactionId: UInt64
    #endif
    var productId: ProductId
    var viewModel: PurchaseInfoViewModel
    
    public var body: some View {
        VStack {
            SheetBarView(showSheet: $showPurchaseInfoSheet, title: "交易信息", sysImage: "creditcard.circle")
            
            Image(productId)
                .resizable()
                .frame(maxWidth: 85, maxHeight: 85)
                .aspectRatio(contentMode: .fit)
                .cornerRadius(25) 
            
            ScrollView {
                if let epi = extendedPurchaseInfo, epi.isPurchased {
                    
                    VStack {
                        PurchaseInfoFieldView(fieldName: "产品名称:", fieldValue: epi.name)
                        PurchaseInfoFieldView(fieldName: "产品 ID:", fieldValue: epi.productId)
                        PurchaseInfoFieldView(fieldName: "产品价格:", fieldValue: epi.purchasePrice ?? "未知")
                        
                        if epi.productType == .nonConsumable {
                            PurchaseInfoFieldView(fieldName: "购买日期:", fieldValue: epi.purchaseDateFormatted ?? "未知")
                            PurchaseInfoFieldView(fieldName: "交易 ID:", fieldValue: String(epi.transactionId ?? UInt64.min))
                            PurchaseInfoFieldView(fieldName: "购买类型:", fieldValue: epi.ownershipType == nil ? "未知" : (epi.ownershipType! == .purchased ? "私人购买" : "家庭购买"))
                            PurchaseInfoFieldView(fieldName: "注意事项:", fieldValue: "\(epi.revocationDate == nil ? "-" : "购买撤销于： \(epi.revocationDateFormatted ?? "") \(epi.revocationReason == .developerIssue ? "(开发者问题)" : "(其他问题)")")")
                            
                        } else {
                            Caption2Font(scaleFactor: storeHelper.fontScaleFactor) { Text("没有其他可用的购买信息")}
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(EdgeInsets(top: 1, leading: 5, bottom: 0, trailing: 5))
                        }
                    }
                    
                    Divider().padding(.bottom)
                    
                    #if os(iOS)
                    DisclosureGroup(isExpanded: $showManagePurchase, content: {
                        Button(action: {
                            if Utils.isSimulator() { StoreLog.event("警告：您不能向模拟器申请退款。您必须使用沙盒环境")}
                            if let tid = epi.transactionId {
                                refundRequestTransactionId = tid
                                withAnimation { showRefundSheet.toggle()}
                            }
                        }) {
                            Label(title: { BodyFont(scaleFactor: storeHelper.fontScaleFactor) { Text("请求退款")}.padding()},
                                  icon:  { Image(systemName: "creditcard.circle").bodyImageNotRounded().frame(height: 24)})
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                        
                    }) {
                        Label(title: { BodyFont(scaleFactor: storeHelper.fontScaleFactor) { Text("管理购买")}.padding()},
                              icon:  { Image(systemName: "creditcard.circle").bodyImageNotRounded().frame(height: 24)})
                    }
                    .onTapGesture { withAnimation { showManagePurchase.toggle() }}
                    .padding(EdgeInsets(top: 0, leading: 20, bottom: 5, trailing: 20))
                    
                    #elseif os(macOS)
                    DisclosureGroup(isExpanded: $showManagePurchase, content: {
                        Button(action: {
                            if  let sRefundUrl = storeHelper.configurationProvider?.value(configuration: .requestRefund) ?? Configuration.requestRefund.value(),
                                let refundUrl = URL(string: sRefundUrl) {
                                NSWorkspace.shared.open(refundUrl)
                            }
                        }) { Label("请求退款", systemImage: "creditcard.circle")}.macOSStyle()

                    }) {
                        Label(title: { BodyFont(scaleFactor: storeHelper.fontScaleFactor) { Text("管理购买")}.padding()},
                              icon:  { Image(systemName: "creditcard.circle").bodyImageNotRounded().frame(height: 24)})
                    }
                    .onTapGesture { withAnimation { showManagePurchase.toggle()}}
                    .padding(EdgeInsets(top: 0, leading: 20, bottom: 5, trailing: 20))
                    #endif
                    
                    Caption2Font(scaleFactor: storeHelper.fontScaleFactor) { Text("如果购买未按预期进行，您可以向App Store申请退款。这需要您向应用商店进行身份验证。请注意，此应用无权访问用于登录应用商店的凭据。")}
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding()
                    
                } else {
                    TitleFont(scaleFactor: storeHelper.fontScaleFactor) { Text("没有可用的购买信息")}
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(EdgeInsets(top: 1, leading: 5, bottom: 0, trailing: 5))
                }
            }
        }
        .task { extendedPurchaseInfo = await viewModel.extendedPurchaseInfo(for: productId)}
        #if os(macOS)
        .frame(minWidth: 650, idealWidth: 650, maxWidth: 650, minHeight: 680, idealHeight: 680, maxHeight: 680)
        .fixedSize(horizontal: true, vertical: true)
        #endif
    }
}

@available(tvOS 15.0, *)
struct PurchaseInfoFieldView: View {
    let fieldName: String
    let fieldValue: String
    let edgeInsetsFieldValue = EdgeInsets(top: 7, leading: 5, bottom: 0, trailing: 5)
    
    #if os(iOS)
    let edgeInsetsFieldName = EdgeInsets(top: 7, leading: 10, bottom: 0, trailing: 5)
    let width: CGFloat = 95
    #elseif os(macOS)
    let edgeInsetsFieldName = EdgeInsets(top: 7, leading: 25, bottom: 0, trailing: 5)
    let width: CGFloat = 140
    #elseif os(tvOS)
    let edgeInsetsFieldName = EdgeInsets(top: 7, leading: 25, bottom: 0, trailing: 5)
    let width: CGFloat = 140
    #endif
    
    var body: some View {
        HStack {
            PurchaseInfoFieldText(text: fieldName).foregroundColor(.secondary).frame(width: width, alignment: .leading).padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 5))
            PurchaseInfoFieldText(text:fieldValue).foregroundColor(.blue).padding(EdgeInsets(top: 10, leading: 5, bottom: 0, trailing: 5))
            Spacer()
        }
    }
}

@available(tvOS 15.0, *)
struct PurchaseInfoFieldText: View {
    @EnvironmentObject var storeHelper: StoreHelper
    let text: String
    
    var body: some View {
        // 注意：我们有意不支持可缩放字体
        #if os(iOS)
        Text(text).font(.footnote)
        #elseif os(macOS)
        Text(text).font(.title2)
        #endif
    }
}
