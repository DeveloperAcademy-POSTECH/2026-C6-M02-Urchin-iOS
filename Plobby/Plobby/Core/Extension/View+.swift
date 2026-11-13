//
//  View+.swift
//  Plobby
//
//  Created by 이은지 on 11/9/26.
//

import SwiftUI

extension View {

    func floatingButtonShadow(_ rect: CGRect) -> some View {
        frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
    }
    
    func guestTapAllowed() -> some View {
        modifier(GuestTapAllowedModifier())
    }

    /// 안 읽은 알림이 있으면 오른쪽 위에 빨간 점을 띄워요.
    /// `inset.width`만큼 왼쪽으로, `inset.height`만큼 아래로 점을 옮겨요.
    func unreadDot(_ isVisible: Bool, size: CGFloat = 8.scaled, inset: CGSize = .zero) -> some View {
        overlay(alignment: .topTrailing) {
            if isVisible {
                Circle()
                    .fill(Color(.currentError))
                    .frame(width: size, height: size)
                    .offset(x: -inset.width, y: inset.height)
            }
        }
    }
}
