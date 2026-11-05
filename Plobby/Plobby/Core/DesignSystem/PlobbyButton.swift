//
//  PlobbyButton.swift
//  Plobby
//
//  Created by 이은지 on 10/31/26.
//

import SwiftUI

struct PlobbyButton: View {
    
    // MARK: - Properties
    
    @Environment(\.isEnabled) private var isEnabled
    
    let text: String
    var style: Style = .default
    let action: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .plobbyFont(.actionLabel)
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(backgroundColor, in: RoundedRectangle(cornerRadius: 8))
                .overlay {
                    if style == .alternative && isEnabled {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.gray300), lineWidth: 1)
                    }
                }
        }
    }
}

// MARK: - Style

extension PlobbyButton {
    
    /// 비활성(deactivate)은 `.disabled(true)`로 표현
    enum Style {
        case `default`
        case alternative
        case onlyText
    }
    
    private var backgroundColor: Color {
        guard isEnabled else { return Color(.gray300) }
        
        switch style {
        case .default: return Color(.green500)
        case .alternative: return Color(.gray0)
        case .onlyText: return .clear
        }
    }
    
    private var textColor: Color {
        guard isEnabled else { return Color(.textDisabled) }
        
        switch style {
        case .default: return Color(.gray0)
        case .alternative: return Color(.textPrimary)
        case .onlyText: return Color(.textSecondary)
        }
    }
}
