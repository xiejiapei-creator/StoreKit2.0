//
//  StoreErrorView.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/5.
//

import SwiftUI

/// 显示错误视图
@available(tvOS 15.0, *)
public struct StoreErrorView: View {
    @EnvironmentObject var storeHelper: StoreHelper
    
    public var body: some View {
        Title2Font(scaleFactor: storeHelper.fontScaleFactor) { Text("商店出错了～")}
            .foregroundColor(.white)
            .padding()
            .frame(height: 40)
            .background(Color.red)
            .cornerRadius(25)
    }
}

@available(tvOS 15.0, *)
struct StoreErrorView_Previews: PreviewProvider {
    static var previews: some View {
        StoreErrorView()
    }
}

