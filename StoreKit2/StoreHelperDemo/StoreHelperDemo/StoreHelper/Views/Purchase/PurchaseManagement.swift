//
//  PurchaseManagement.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/5.
//

import SwiftUI
import StoreKit

/// 请注意，用于请求退款和管理订阅的API目前不适用于macOS
/// 允许用户管理订阅、恢复购买、请求退款和联系我们
@available(tvOS 15.0, *)
public struct PurchaseManagement: View {
    @Environment(\.openURL) var openURL
    @EnvironmentObject var storeHelper: StoreHelper
    @State private var purchasesRestored: Bool = false
    
    #if os(iOS)
    @State private var showManageSubscriptions = false
    
    public var body: some View {
        if  storeHelper.hasProducts,
            let sContactUrl = storeHelper.configurationProvider?.value(configuration: .contactUsUrl) ?? Configuration.contactUsUrl.value(),
            let contactUrl = URL(string: sContactUrl) {
            
            Menu {
                Button(action: {
                    if Utils.isSimulator() { StoreLog.event("您无法管理来自模拟器的订阅。您必须使用沙盒环境")}
                    showManageSubscriptions.toggle()

                }) { Label("管理订阅", systemImage: "rectangle.stack.fill.badge.person.crop")}
                .disabled(!storeHelper.hasSubscriptionProducts)
                
                Button(action: { restorePurchases()}) { Label("恢复购买", systemImage: "purchased")}
                Button(action: { openURL(contactUrl)}) { Label("联系我们", systemImage: "bubble.right")}

            } label: { Label("", systemImage: "line.3.horizontal").labelStyle(.iconOnly)}
            .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
        }
    }
    
    #elseif os(macOS)
    public var body: some View {
        if  storeHelper.hasProducts,
            let sContactUrl = storeHelper.configurationProvider?.value(configuration: .contactUsUrl) ?? Configuration.contactUsUrl.value(),
            let contactUrl = URL(string: sContactUrl) {
            
            let edgeInsets = EdgeInsets(top: 10, leading: 3, bottom: 10, trailing: 3)
            VStack {
                HStack {
                    Button(action: { restorePurchases()}) {
                        Label(title: { BodyFont(scaleFactor: storeHelper.fontScaleFactor) { Text("恢复购买")}.padding()},
                              icon:  { Image(systemName: "purchased").bodyImageNotRounded().frame(height: 24)})
                    }
                    .macOSStyle(padding: edgeInsets)
                    .disabled(purchasesRestored)
                    
                    Button(action: { openURL(contactUrl)}) {
                        Label(title: { BodyFont(scaleFactor: storeHelper.fontScaleFactor) { Text("联系我们")}.padding()},
                              icon:  { Image(systemName: "bubble.right").bodyImageNotRounded().frame(height: 24)})
                    }
                    .macOSStyle(padding: edgeInsets)
                }
                
                CaptionFont(scaleFactor: storeHelper.fontScaleFactor) { Text("通常不需要手动恢复以前的购买。仅当此应用程序无法正确识别您以前的购买时，单击恢复购买。系统将提示您使用App Store进行身份验证。请注意，此应用无权访问用于登录应用商店的凭据.")}
                    .multilineTextAlignment(.center)
                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 10))
                    .foregroundColor(.secondary)
            }
        }
    }
    #elseif os(tvOS)
    public var body: some View {
        if  storeHelper.hasProducts,
            let sContactUrl = storeHelper.configurationProvider?.value(configuration: .contactUsUrl) ?? Configuration.contactUsUrl.value(),
            let contactUrl = URL(string: sContactUrl) {
            
            VStack {
                HStack {
                    Button(action: { restorePurchases()}) {
                        Label(title: { BodyFont(scaleFactor: storeHelper.fontScaleFactor) { Text("恢复购买")}.padding()},
                              icon:  { Image(systemName: "purchased").bodyImageNotRounded().frame(height: 24)})
                    }
                    .disabled(purchasesRestored)
                    
                    Button(action: { openURL(contactUrl)}) {
                        Label(title: { BodyFont(scaleFactor: storeHelper.fontScaleFactor) { Text("联系我们")}.padding()},
                              icon:  { Image(systemName: "bubble.right").bodyImageNotRounded().frame(height: 24)})
                    }
                }
                
                CaptionFont(scaleFactor: storeHelper.fontScaleFactor) { Text("通常不需要手动恢复以前的购买。仅当此应用程序无法正确识别您以前的购买时，单击恢复购买。系统将提示您使用App Store进行身份验证。请注意，此应用无权访问用于登录应用商店的凭据.")}
                    .multilineTextAlignment(.center)
                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 10))
                    .foregroundColor(.secondary)
            }
        }
    }
    #endif

    /// 恢复以前的用户购买。对于StoreKit2，这通常是不必要的，只应在响应显式用户操作时执行。将导致用户必须使用App Store进行身份验证。
    private func restorePurchases() {
        Task.init {
            try? await AppStore.sync()
            purchasesRestored.toggle()
        }
    }
}


