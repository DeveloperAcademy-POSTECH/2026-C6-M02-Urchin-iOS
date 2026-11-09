//
//  BeachChip.swift
//  Plobby
//
//  Created by 이은지 on 11/4/26.
//

import SwiftUI

/// 관심 해변 칩
/// - 관심 해변 목록(`.favorite`)과 추가 버튼(`.add`)에 사용합니다.
/// - 지도 서치바 아래 칩은 `.searchFavorite`, 선택된 칩은 `.selectedSearchFavorite`를 사용합니다.
///
struct BeachChip: View {

    // MARK: - Properties

    let title: String
    var style: Style = .favorite

    // MARK: - Body

    var body: some View {
        HStack(spacing: style.spacing.scaled) {
            Image(style.image)
                .resizable()
                .frame(width: style.iconSize.scaled, height: style.iconSize.scaled)
                .frame(width: style.iconFrameSize.scaled, height: style.iconFrameSize.scaled)

            Text(title)
                .plobbyFont(style.font)
                .foregroundStyle(style.textColor)
                .lineLimit(1)
        }
        .padding(.leading, style.leadingPadding.scaled)
        .padding(.trailing, style.trailingPadding.scaled)
        .frame(height: style.height.scaled)
        .background(
            style.backgroundColor,
            in: RoundedRectangle(cornerRadius: style.cornerRadius.scaled)
        )
        .overlay {
            RoundedRectangle(cornerRadius: style.cornerRadius.scaled)
                .stroke(style.strokeColor, lineWidth: 1)
        }
    }
}

// MARK: - Style

extension BeachChip {

    enum Style {
        case favorite
        case add
        case searchFavorite
        case selectedSearchFavorite

        var image: ImageResource {
            switch self {
            case .favorite: .starGreen
            case .add: .plus
            case .searchFavorite: .backgroundStarGreen
            case .selectedSearchFavorite: .backgroundWhiteStar
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .favorite: 24
            case .add: 14
            case .searchFavorite, .selectedSearchFavorite: 16
            }
        }

        var textColor: Color {
            switch self {
            case .favorite, .searchFavorite: return .textPrimary
            case .add: return .textSecondary
            case .selectedSearchFavorite: return .currentBrandText
            }
        }
        
        var font: PlobbyTypography {
            switch self {
            case .favorite, .add, .selectedSearchFavorite: .labelSelected
            case .searchFavorite: .label
            }
        }

        /// 아이콘이 차지하는 칸. 서치바 아래 칩은 아이콘 크기 그대로 써요.
        var iconFrameSize: CGFloat {
            switch self {
            case .favorite, .add: 24
            case .searchFavorite, .selectedSearchFavorite: 16
            }
        }

        var spacing: CGFloat {
            switch self {
            case .favorite, .add: 4
            case .searchFavorite, .selectedSearchFavorite: 6
            }
        }

        var leadingPadding: CGFloat {
            switch self {
            case .favorite, .add: 8
            case .searchFavorite, .selectedSearchFavorite: 12
            }
        }

        var trailingPadding: CGFloat {
            switch self {
            case .favorite, .add: 16
            case .searchFavorite, .selectedSearchFavorite: 12
            }
        }

        var height: CGFloat {
            switch self {
            case .favorite, .add: 44
            case .searchFavorite, .selectedSearchFavorite: 36
            }
        }

        /// 서치바 아래 칩은 캡슐 모양이에요.
        var cornerRadius: CGFloat {
            switch self {
            case .favorite, .add: 12
            case .searchFavorite, .selectedSearchFavorite: 18
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .favorite, .add: return .gray50
            case .searchFavorite: return .white
            case .selectedSearchFavorite: return .surfaceBrandSubtle
            }
        }
        
        var strokeColor: Color {
            switch self {
            case .favorite, .add: return .currentWarmBorder
            case .searchFavorite: return .gray200
            case .selectedSearchFavorite: return .green500
            }
        }
    }
}
