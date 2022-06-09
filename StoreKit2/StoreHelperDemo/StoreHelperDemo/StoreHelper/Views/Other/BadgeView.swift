//
//  BadgeView.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/5.
//

import SwiftUI

/// 显示一个小图像，为产品的购买状态提供视觉线索
@available(tvOS 15.0, *)
public struct BadgeView: View {
    
    @Binding var purchaseState: PurchaseState
    
    @available(tvOS 15.0, *)
    public var body: some View {
        
        if let options = badgeOptions() {
            Image(systemName: options.badgeName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 25, height: 25)
                .foregroundColor(options.fgColor)
        }
    }
    
    @available(tvOS 15.0, *)
    public func badgeOptions() -> (badgeName: String, fgColor: Color)? {
        switch purchaseState {
            case .notStarted:               return nil
            case .userCannotMakePayments:   return (badgeName: "nosign", Color.red)
            case .inProgress:               return (badgeName: "hourglass", Color.cyan)
            case .purchased:                return (badgeName: "checkmark", Color.green)
            case .pending:                  return (badgeName: "hourglass", Color.orange)
            case .cancelled:                return (badgeName: "person.crop.circle.fill.badge.xmark", Color.blue)
            case .failed:                   return (badgeName: "hand.raised.slash", Color.red)
            case .failedVerification:       return (badgeName: "hand.thumbsdown.fill", Color.red)
            case .unknown:                  return nil
        }
    }
}

@available(tvOS 15.0, *)struct PurchasedView_Previews: PreviewProvider {
    
    static var previews: some View {
        VStack {
            BadgeView(purchaseState: .constant(.userCannotMakePayments))
            BadgeView(purchaseState: .constant(.inProgress))
            BadgeView(purchaseState: .constant(.purchased))
            BadgeView(purchaseState: .constant(.pending))
            BadgeView(purchaseState: .constant(.cancelled))
            BadgeView(purchaseState: .constant(.failed))
            BadgeView(purchaseState: .constant(.failedVerification))
        }
    }
}
