//
//  ConsumableBadgeView.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/5.
//

import SwiftUI

/// 显示带有耗材购买次数的计数徽章
@available(tvOS 15.0, *)
public struct ConsumableBadgeView: View {
    
    @Binding var count : Int
    
    public var body: some View {
        
        ZStack {
            Capsule()
                .fill(Color.red)
                .frame(width: 30, height: 30, alignment: .topTrailing)
                .position(CGPoint(x: 70, y: 10))
            
            Text(String(count)).foregroundColor(.white)
                .font(Font.system(size: 20).bold()).position(CGPoint(x: 70, y: 10))
        }
    }
}


