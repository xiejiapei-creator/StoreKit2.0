//
//  StoreHelperDemoApp.swift
//  StoreHelperDemo
//
//  Created by 谢佳培 on 2022/6/5.
//

import SwiftUI

@main
struct StoreHelperDemoApp: App {
    @StateObject var storeHelper = StoreHelper()
    
    var body: some Scene {
        WindowGroup {
            LFTMainView()
                .environmentObject(storeHelper)
                .onAppear { storeHelper.start()}
        }
    }
}



