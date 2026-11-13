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
}
