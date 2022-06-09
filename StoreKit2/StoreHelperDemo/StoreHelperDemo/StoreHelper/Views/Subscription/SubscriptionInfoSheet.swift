//
//  SubscriptionInfoSheet.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/5.
//

import SwiftUI

// Subscriptions:   [Products].[ProductListView].[SubscriptionListViewRow].[SubscriptionView].[if purchased].[SubscriptionInfoView].[SubscriptionInfoSheet]

@available(tvOS 15.0, *)
public struct SubscriptionInfoSheet: View {
    @EnvironmentObject var storeHelper: StoreHelper
    @State private var showManageSubscriptionsSheet = false
    @State private var extendedSubscriptionInfo: ExtendedSubscriptionInfo?
    @Binding var showPurchaseInfoSheet: Bool
    var productId: ProductId
    var viewModel: SubscriptionInfoViewModel
    
    public var body: some View {
        VStack {
            SheetBarView(showSheet: $showPurchaseInfoSheet, title: "订阅信息", sysImage: "creditcard.circle")
            
            Image(productId)
                .resizable()
                .frame(maxWidth: 85, maxHeight: 85)
                .aspectRatio(contentMode: .fit)
                .cornerRadius(25)
            
            ScrollView {
                if let esi = extendedSubscriptionInfo, esi.isPurchased {
                    
                    VStack {
                        Group {
                            PurchaseInfoFieldView(fieldName: "产品名称:", fieldValue: esi.name)
                            PurchaseInfoFieldView(fieldName: "产品 ID:", fieldValue: esi.productId)
                            PurchaseInfoFieldView(fieldName: "价格:", fieldValue: esi.purchasePrice ?? "未知")
                            PurchaseInfoFieldView(fieldName: "订阅升级:", fieldValue: esi.upgraded == nil ? "未知" : (esi.upgraded! ? "Yes" : "No"))
                            if let willAutoRenew = esi.autoRenewOn {
                                if willAutoRenew {
                                    PurchaseInfoFieldView(fieldName: "订阅状态:", fieldValue: esi.subscribedtext ?? "未知")
                                    PurchaseInfoFieldView(fieldName: "自动续订:", fieldValue: "是")
                                    PurchaseInfoFieldView(fieldName: "更新周期:", fieldValue: esi.renewalPeriod ?? "未知")
                                    PurchaseInfoFieldView(fieldName: "更新日期:", fieldValue: esi.renewalDate ?? "未知")
                                    PurchaseInfoFieldView(fieldName: "过期时间:", fieldValue: esi.renewsIn ?? "未知")
                                } else {
                                    PurchaseInfoFieldView(fieldName: "订阅状态:", fieldValue: "取消订阅")
                                    PurchaseInfoFieldView(fieldName: "自动续订:", fieldValue: "否")
                                    PurchaseInfoFieldView(fieldName: "更新周期:", fieldValue: "不再续订")
                                    PurchaseInfoFieldView(fieldName: "过期时间:", fieldValue: esi.renewalDate ?? "未知")
                                    PurchaseInfoFieldView(fieldName: "剩余天数:", fieldValue: esi.renewsIn ?? "未知")
                                }
                            }
                        }
                        
                        Group {
                            Divider()
                            Text("最近一笔交易").foregroundColor(.secondary)
                            PurchaseInfoFieldView(fieldName: "日期:", fieldValue: esi.purchaseDateFormatted ?? "未知")
                            PurchaseInfoFieldView(fieldName: "ID:", fieldValue: String(esi.transactionId ?? UInt64.min))
                            PurchaseInfoFieldView(fieldName: "购买类型:", fieldValue: esi.ownershipType == nil ? "未知" : (esi.ownershipType! == .purchased ? "私人购买" : "家庭购买"))
                            PurchaseInfoFieldView(fieldName: "Notes:", fieldValue: "\(esi.revocationDate == nil ? "-" : "撤销购买于 \(esi.revocationDateFormatted ?? "") \(esi.revocationReason == .developerIssue ? "(开发者问题)" : "(其他问题)")")")
                        }
                    }
                    
                    Divider().padding(.bottom)
                    
                    #if os(iOS)
                    Button(action: {
                        if Utils.isSimulator() { StoreLog.event("警告：您不能向模拟器申请退款。您必须使用沙盒环境。")}
                        withAnimation { showManageSubscriptionsSheet.toggle()}
                    }) {
                        Label(title: { BodyFont(scaleFactor: storeHelper.fontScaleFactor) { Text("管理订阅")}.padding()},
                              icon:  { Image(systemName: "creditcard.circle").bodyImageNotRounded().frame(height: 24)})
                    }
                    .buttonStyle(.borderedProminent)
                    #endif
                    
                    Caption2Font(scaleFactor: storeHelper.fontScaleFactor) { Text("管理订阅可能需要您向应用商店进行身份验证。请注意，此应用无权访问用于登录应用商店的凭据。")}
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
        .task { extendedSubscriptionInfo = await viewModel.extendedSubscriptionInfo()}
        #if os(iOS)
        .manageSubscriptionsSheet(isPresented: $showManageSubscriptionsSheet)  // Not available for macOS
        #elseif os(macOS)
        .frame(minWidth: 650, idealWidth: 650, maxWidth: 650, minHeight: 650, idealHeight: 650, maxHeight: 650)
        .fixedSize(horizontal: true, vertical: true)
        #endif
    }
}

