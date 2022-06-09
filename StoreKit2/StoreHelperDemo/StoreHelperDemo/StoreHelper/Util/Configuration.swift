//
//  Configuration.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/7.
//

import Foundation

/// 允许使用StoreHelper的客户端为StoreHelper所需的静态值插入配置
/// 设置 StoreHelper.configurationProvider 覆盖 Configuration 提供的默认值
public protocol ConfigurationProvider {
    func value(configuration: Configuration) -> String?
}

/// StoreHelper使用的静态配置值
public enum Configuration {
    case appGroupBundleId   // 未存储。常量值。主应用程序和小部件之间共享的容器id
    case contactUsUrl       // 未存储。常量值。用户可以联系应用程序开发人员的URL
    case requestRefund      // 未存储。常量值。macOS上的用户可用于请求IAP退款的URL
    
    public func value() -> String? {
        switch self {
            // 如果您的应用程序支持使用基于IAP的功能的小部件（例如应用程序组）
            // 请返回允许主应用程序和小部件共享数据的组id
            // 例如"group.com.{developer}.{appname}"
            case .appGroupBundleId: return nil  // 返回nil表示没有共享数据
            case .contactUsUrl:     return nil  // 联系人URL。在购买管理视图中使用
            case .requestRefund:    return "https://reportaproblem.apple.com/"  // macOS上的用户可用于请求IAP退款的URL
        }
    }
}

