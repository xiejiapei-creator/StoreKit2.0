//
//  Utils.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/7.
//

import Foundation

/// 各种实用方法
public struct Utils {
    
    /// 检测应用程序是否作为预览运行
    public static var isRunningPreview: Bool { ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" }
    
    /// 是否处于Debug环境
    private static let debug: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    
    /// 是否处于模拟器中
    private static let simulator: Bool = {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }()
    
    public static func isDebug() -> Bool { return self.debug }
    public static func isRelease() -> Bool { return !self.debug }
    public static func isSimulator() -> Bool { return self.simulator }
}

