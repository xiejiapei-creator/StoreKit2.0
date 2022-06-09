//
//  VersionInfo.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/5.
//

import SwiftUI

/// 版本信息
@available(tvOS 15.0, *)
public struct VersionInfo: View {
    @EnvironmentObject var storeHelper: StoreHelper
    @State private var appName = ""
    @State private var versionInfo = ""
    @State private var buildInfo = ""
    
    let insets = EdgeInsets(top: 0, leading: 2, bottom: 1, trailing: 1)
    
    public init() {}
    
    public var body: some View {
        VStack {
            Spacer()
            HStack {
                // StoreHelper将在资产目录中查找名为“AppStoreIcon”的图像
                Image("AppStoreIcon").resizable().frame(width: 75, height: 75)
                
                VStack {
                    SubHeadlineFont(scaleFactor: storeHelper.fontScaleFactor) { Text("\(appName) version \(versionInfo)")}.padding(insets)
                    SubHeadlineFont(scaleFactor: storeHelper.fontScaleFactor) { Text("Build \(buildInfo)")}.padding(insets)
                }
            }
            .padding()
        }
        .onAppear {
            // 从Info.plist中读取应用程序名称、版本和版本号
            // 对于应用程序名称，我们首先查找具有CFBundleDisplayName的条目
            // 这允许开发人员使用应用程序的特定名称覆盖Xcode项目名称(CFBundleName)
            // 如果缺少此键，则默认为(CFBundleName)它应该始终存在
            if let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") { appName = "\(name as? String ?? "StoreHelper")" }
            else if let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") { appName = "\(name as? String ?? "StoreHelper")" }
            
            if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") { versionInfo = "\(version as? String ?? "未知")" }
            if let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") { buildInfo = "\(build as? String ?? "未知")" }
        }
    }
}
