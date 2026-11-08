//
//  BeachChip.swift
//  Plobby
//
//  Created by 이은지 on 11/4/26.
//

import SwiftUI

/// 관심 해변 칩
/// - 관심 해변 목록(`.favorite`)과 추가 버튼(`.add`)에 사용합니다.
///
struct BeachChip: View {

    // MARK: - Properties

    let title: String
    var style: Style = .favorite

    // MARK: - Body

    var body: some View {
        HStack(spacing: 4.scaled) {
            Image(style.image)
                .resizable()
                .frame(width: style.iconSize.scaled, height: style.iconSize.scaled)
                .frame(width: 24.scaled, height: 24.scaled)

            Text(title)
                .plobbyFont(.labelSelected)
                .foregroundStyle(style.textColor)
        }
        .padding(.leading, 8.scaled)
        .padding(.trailing, 16.scaled)
        .frame(height: 44.scaled)
        .background(Color(.gray50), in: RoundedRectangle(cornerRadius: 12.scaled))
        .overlay {
            RoundedRectangle(cornerRadius: 12.scaled)
                .stroke(Color(.currentWarmBorder), lineWidth: 1)
        }
    }
}

// MARK: - Style

extension BeachChip {

    enum Style {
        case favorite
        case add

        var image: ImageResource {
            switch self {
            case .favorite: .starGreen
            case .add: .plus
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .favorite: 24
            case .add: 14
            }
        }

        var textColor: Color {
            switch self {
            case .favorite: Color(.textPrimary)
            case .add: Color(.textSecondary)
            }
        }
    }
}
