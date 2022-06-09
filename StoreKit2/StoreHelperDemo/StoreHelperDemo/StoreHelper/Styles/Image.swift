//
//  BodyImage.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/5.
//

import SwiftUI
import UIKit

@available(tvOS 15.0, *)
public extension Image {
    func bodyImage() -> some View {
        self
            .resizable()
            .cornerRadius(15)
            .aspectRatio(contentMode: .fit)
            #if os(macOS)
            .frame(maxWidth: 1200)
            .padding(EdgeInsets(top: 10, leading: 0, bottom: 20, trailing: 10))
            #endif
    }
    
    func bodyImageNotRounded() -> some View {
        self
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
    
    #if os(macOS)
    func bodyImageConstrained(width: CGFloat? = nil, height: CGFloat? = nil) -> some View {
        self
            .resizable()
            .cornerRadius(15)
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: width ?? 1200, maxHeight: height ?? .infinity)
            .padding()
    }
    
    func bodyImageConstrainedNoPadding(width: CGFloat? = nil, height: CGFloat? = nil) -> some View {
        self
            .resizable()
            .cornerRadius(15)
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: width ?? 1200, maxHeight: height ?? .infinity)
    }
    
    func bodyImageConstrainedNoPaddingNoCorner(width: CGFloat? = nil, height: CGFloat? = nil) -> some View {
        self
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: width ?? 1200, maxHeight: height ?? .infinity)
    }
    #endif
}

