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
    var isLoading = false
    let action: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(textColor)
                } else {
                    Text(text)
                        .plobbyFont(.actionLabel)
                        .foregroundStyle(textColor)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54.scaled)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 8.scaled))
            .overlay {
                if style == .alternative && isActive {
                    RoundedRectangle(cornerRadius: 8.scaled)
                        .stroke(Color(.gray300), lineWidth: 1)
                }
            }
        }
        .allowsHitTesting(!isLoading)
    }
}

// MARK: - Style

extension PlobbyButton {
    
    /// 비활성(deactivate)은 `.disabled(true)`로 표현
    enum Style {
        case `default`
        case highlight
        case alternative
        case onlyText
    }
    
    /// 로딩 중에는 버튼이 비활성이어도 활성 색을 유지해요.
    private var isActive: Bool {
        isEnabled || isLoading
    }

    private var backgroundColor: Color {
        guard isActive else { return Color(.gray300) }
        
        switch style {
        case .default: return Color(.green500)
        case .highlight: return Color(.darkBGGreen)
        case .alternative: return Color(.gray0)
        case .onlyText: return .clear
        }
    }
    
    private var textColor: Color {
        guard isActive else { return Color(.textDisabled) }
        
        switch style {
        case .default, .highlight: return Color(.gray0)
        case .alternative: return Color(.textPrimary)
        case .onlyText: return Color(.textSecondary)
        }
    }
}
