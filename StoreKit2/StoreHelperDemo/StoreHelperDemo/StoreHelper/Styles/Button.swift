//
//  Button.swift
//  StoreHelper
//
//  Created by 谢佳培 on 2022/6/5.
//

import SwiftUI

/// macOS 按钮风格
#if os(macOS)
public struct macOSButtonStyle: ButtonStyle {
    var foregroundColor: Color = .white
    var backgroundColor: Color = .blue
    var pressedColor: Color = .secondary
    var opacity: Double = 1
    var padding: EdgeInsets = EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
    var scaleFactor: Double = FontUtil.baseDynamicTypeSize(for: .large)
    
    public func makeBody(configuration: Self.Configuration) -> some View {
        Title2Font(scaleFactor: self.scaleFactor) { configuration.label }
            .padding(15)
            .foregroundColor(foregroundColor)
            .background(configuration.isPressed ? pressedColor : backgroundColor).opacity(opacity)
            .cornerRadius(5)
            .padding(padding)
    }
}

public extension View {
    /// macOS 视图风格
    func macOSStyle(foregroundColor: Color = .white, backgroundColor: Color = .blue, pressedColor: Color = .secondary, padding: EdgeInsets = EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)) -> some View {
        self.buttonStyle(macOSButtonStyle(foregroundColor: foregroundColor, backgroundColor: backgroundColor, pressedColor: pressedColor, padding: padding))
    }
    
    /// macOS 透明样式
    func macOSTransparentStyle(foregroundColor: Color = .blue, backgroundColor: Color = .white, pressedColor: Color = .secondary) -> some View {
        self.buttonStyle(macOSButtonStyle(foregroundColor: foregroundColor, backgroundColor: backgroundColor, pressedColor: pressedColor, opacity: 0))
    }
}

public extension Button {
    /// macOS 圆角按钮
    func macOSRoundedStyle() -> some View {
        self
            .frame(width: 30, height: 30)
            .buttonStyle(.plain)
            .foregroundColor(Color.white)
            .background(Color.blue)
            .clipShape(Circle())
    }
}

public extension Text {
    /// macOS 窄按钮样式
    func macOSNarrowButtonStyle() -> some View {
        self
            .frame(width: 100, height: 40)
            .buttonStyle(.plain)
            .foregroundColor(Color.white)
            .background(Color.blue)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    /// macOS 窄按钮样式
    func macOSNarrowButtonStyle(disabled: Bool = false) -> some View {
        self
            .frame(width: 100, height: 40)
            .buttonStyle(.plain)
            .foregroundColor(disabled ? Color.secondary : Color.white)
            .background(disabled ? Color.gray : Color.blue)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
#endif
