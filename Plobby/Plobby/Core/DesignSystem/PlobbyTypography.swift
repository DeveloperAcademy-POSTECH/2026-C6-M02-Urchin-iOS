//
//  PlobbyTypography.swift
//  Plobby
//
//  Created by 이은지 on 11/5/26.
//

import SwiftUI
import UIKit

enum PretendardWeight: String {
    case semiBold = "Pretendard-SemiBold"
    case medium = "Pretendard-Medium"
    case regular = "Pretendard-Regular"
}

enum PlobbyTypography {
    case heading
    case cardTitle
    case body
    case actionLabel
    case notification
    case label
    case labelSelected
    case helper
    case metadata
    case metric

    var weight: PretendardWeight {
        switch self {
        case .heading: .semiBold
        case .cardTitle: .semiBold
        case .body: .regular
        case .actionLabel: .semiBold
        case .notification: .medium
        case .label: .medium
        case .labelSelected: .semiBold
        case .helper: .regular
        case .metadata: .regular
        case .metric: .semiBold
        }
    }

    var size: CGFloat {
        switch self {
        case .heading: 20
        case .cardTitle: 17
        case .body: 16
        case .actionLabel: 16
        case .notification: 15
        case .label: 14
        case .labelSelected: 14
        case .helper: 13
        case .metadata: 12
        case .metric: 22
        }
    }

    var lineHeight: CGFloat {
        switch self {
        case .heading: 28
        case .cardTitle: 22
        case .body: 24
        case .actionLabel: 24
        case .notification: 22
        case .label: 20
        case .labelSelected: 20
        case .helper: 20
        case .metadata: 18
        case .metric: 28
        }
    }
}

struct TypographyModifier: ViewModifier {
    let typography: PlobbyTypography

    func body(content: Content) -> some View {
        let uiFont = UIFont(name: typography.weight.rawValue, size: typography.size)
            ?? .systemFont(ofSize: typography.size)
        let extraLineSpacing = max(0, typography.lineHeight - uiFont.lineHeight)

        content
            .font(.custom(typography.weight.rawValue, fixedSize: typography.size))
            .lineSpacing(extraLineSpacing)
            .padding(.vertical, extraLineSpacing / 2)
    }
}

extension View {
    func plobbyFont(_ typography: PlobbyTypography) -> some View {
        modifier(TypographyModifier(typography: typography))
    }
}
