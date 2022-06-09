//
//  AppGroupSupport.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/8.
//
import SwiftUI

public struct AppGroupSupport {
    
    public static func syncPurchase(configProvider: ConfigurationProvider?, productId: String, purchased: Bool) {
        // 更新我们与组中其他成员共享的容器中的UserDefault 通用域名格式：group.com.{developer}.{appname} AppGroup
        // 目前，这样做是为了让widget可以知道购买了哪些iap
        // 请注意，小部件不能直接使用StoreHelper，因为它们不购买任何东西，并且就StoreKit而言，它们不被视为进行购买的应用程序的一部分
        guard let id = configProvider?.value(configuration: .appGroupBundleId) ?? Configuration.appGroupBundleId.value() else { return }
        if let defaults = UserDefaults(suiteName: id) { defaults.set(purchased, forKey: productId)}
    }
    
    public static func isPurchased(configProvider: ConfigurationProvider?, productId: String) -> Bool {
        guard let id = configProvider?.value(configuration: .appGroupBundleId) ?? Configuration.appGroupBundleId.value() else { return false }
        var purchased = false
        if let defaults = UserDefaults(suiteName: id) { purchased = defaults.bool(forKey: productId)}
        return purchased
    }
}

