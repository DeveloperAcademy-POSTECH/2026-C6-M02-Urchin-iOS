//
//  BeachChip.swift
//  Plobby
//
//  Created by 이은지 on 11/4/26.
//

import SwiftUI

/// 관심 해변 칩
/// - 지도 서치바 아래와 해변 검색 화면의 관심 해변에 `.searchFavorite`를 사용합니다.
/// - 지도에서 시트가 열린 해변의 칩은 `.selectedSearchFavorite`를 사용합니다.
///
struct BeachChip: View {

    // MARK: - Properties

    let title: String
    var style: Style = .searchFavorite

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
        case searchFavorite
        case selectedSearchFavorite

        var image: ImageResource {
            switch self {
            case .searchFavorite: .backgroundStarGreen
            case .selectedSearchFavorite: .backgroundWhiteStar
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .searchFavorite, .selectedSearchFavorite: 16
            }
        }

        var textColor: Color {
            switch self {
            case .searchFavorite: return .textPrimary
            case .selectedSearchFavorite: return .currentBrandText
            }
        }
        
        var font: PlobbyTypography {
            switch self {
            case .selectedSearchFavorite: .labelSelected
            case .searchFavorite: .label
            }
        }

        var iconFrameSize: CGFloat {
            switch self {
            case .searchFavorite, .selectedSearchFavorite: 16
            }
        }

        var spacing: CGFloat {
            switch self {
            case .searchFavorite, .selectedSearchFavorite: 6
            }
        }

        var leadingPadding: CGFloat {
            switch self {
            case .searchFavorite, .selectedSearchFavorite: 12
            }
        }

        var trailingPadding: CGFloat {
            switch self {
            case .searchFavorite, .selectedSearchFavorite: 12
            }
        }

        var height: CGFloat {
            switch self {
            case .searchFavorite, .selectedSearchFavorite: 36
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .searchFavorite, .selectedSearchFavorite: 18
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .searchFavorite: return .white
            case .selectedSearchFavorite: return .surfaceBrandSubtle
            }
        }
        
        var strokeColor: Color {
            switch self {
            case .searchFavorite: return .gray200
            case .selectedSearchFavorite: return .green500
            }
        }
    }
}
