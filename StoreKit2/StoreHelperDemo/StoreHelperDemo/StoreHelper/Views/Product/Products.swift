//
//  Products.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/5.
//
// Non-Consumables: [Products].[ProductListView].[ProductListViewRow]......[ProductView]......[if purchased].[PurchaseInfoView].....[PurchaseInfoSheet]

import SwiftUI
import StoreKit

/// 产品视图
@available(tvOS 15.0, *)
public struct Products: View {
    @EnvironmentObject var storeHelper: StoreHelper
    @State private var showManageSubscriptions = false
    @State private var showRefundSheet = false
    @State private var refundRequestTransactionId: UInt64 = UInt64.min
    @State private var canMakePayments: Bool = false
    @State private var purchasesRestored: Bool = false
    @State private var showRefundAlert: Bool = false
    @State private var refundAlertText: String = ""
    
    private var productInfoCompletion: ((ProductId) -> Void)
    
    #if os(macOS)
    @State private var showManagePurchases = false
    #endif
    
    public init(productInfoCompletion: @escaping ((ProductId) -> Void)) {
        self.productInfoCompletion = productInfoCompletion
    }
    
    @ViewBuilder public var body: some View {
        VStack {
            #if os(iOS)
            ProductListView(showRefundSheet: $showRefundSheet, refundRequestTransactionId: $refundRequestTransactionId, productInfoCompletion: productInfoCompletion)
            Button(action: {
                Task.init {
                    try? await AppStore.sync()
                    purchasesRestored = true
                }
            }) { BodyFont(scaleFactor: storeHelper.fontScaleFactor) { Text(purchasesRestored ? "购买已恢复" : "恢复购买")}.padding()}
            .buttonStyle(.borderedProminent).padding()
            .disabled(purchasesRestored)
            
            Caption2Font(scaleFactor: storeHelper.fontScaleFactor) { Text("通常不需要手动恢复以前的购买。仅当此应用程序无法正确识别您以前的购买时，点击“恢复购买”。系统将提示您使用App Store进行身份验证。请注意，此应用无权访问用于登录应用商店的凭据。")}
                .multilineTextAlignment(.center)
                .padding(EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 10))
                .foregroundColor(.secondary)
            
            #elseif os(macOS)
            ProductListView(productInfoCompletion: productInfoCompletion)
            DisclosureGroup(isExpanded: $showManagePurchases, content: { PurchaseManagement()}, label: { Label("管理购买", systemImage: "creditcard.circle")})
                .onTapGesture { withAnimation { showManagePurchases.toggle()}}
                .padding(EdgeInsets(top: 0, leading: 20, bottom: 5, trailing: 20))
            
            #elseif os(tvOS)
            ProductListView(productInfoCompletion: productInfoCompletion)
            #endif
            
            if !canMakePayments {
                Spacer()
                SubHeadlineFont(scaleFactor: storeHelper.fontScaleFactor) { Text("不允许在您的设备上购买")}.foregroundColor(.secondary)
            }
        }
        #if os(iOS)
        .navigationBarTitle("可用产品", displayMode: .inline)
        .toolbar { PurchaseManagement() }
        .refundRequestSheet(for: refundRequestTransactionId, isPresented: $showRefundSheet) { refundRequestStatus in
            switch(refundRequestStatus) {
                case .failure(_): refundAlertText = "退款申请提交失败"
                case .success(_): refundAlertText = "退款申请提交成功"
            }

            showRefundAlert.toggle()
        }
        #endif
        .alert(refundAlertText, isPresented: $showRefundAlert) { Button("OK") { showRefundAlert.toggle()}}
        .onAppear { canMakePayments = AppStore.canMakePayments }
        
        VersionInfo()
    }
}

