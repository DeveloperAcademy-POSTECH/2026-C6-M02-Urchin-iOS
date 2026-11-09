//
//  SearchBar.swift
//  Plobby
//
//  Created by 이은지 on 11/7/26.
//

import SwiftUI

/// 검색창 틀
/// - 지도의 검색 버튼, 해변 검색 화면, 관심 해변 선택(BeachPickerView)이 같이 사용합니다.
/// - 왼쪽 아이콘(`leading`)과 내용(`content`)만 화면마다 다릅니다.
/// - 아이콘·글자 색과 폰트는 기본값이라, 화면에서 따로 지정하면 그 값이 우선합니다.
/// - 입력창이면 자동 수정을 끄고 키보드 버튼을 "검색"으로 보여줍니다.
///
struct SearchBar<Leading: View, Content: View>: View {

    // MARK: - Properties

    @ViewBuilder let leading: Leading
    @ViewBuilder let content: Content

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8.scaled) {
            leading
                .font(.system(size: 16.scaled, weight: .medium))
                .foregroundStyle(Color(.textSecondary))
                .frame(width: 24.scaled, height: 24.scaled)

            content
                .plobbyFont(.body)
                .foregroundStyle(Color(.textSecondary))
                .frame(maxWidth: .infinity, alignment: .leading)
                .autocorrectionDisabled()
                .submitLabel(.search)
        }
        .padding(.horizontal, 12.scaled)
        .frame(height: 51.scaled)
        .background(Color(.backgroundDefault), in: RoundedRectangle(cornerRadius: 8.scaled))
        .overlay {
            RoundedRectangle(cornerRadius: 8.scaled)
                .strokeBorder(Color(.borderDefault), lineWidth: 1)
        }
    }
}

// MARK: - Constants

enum SearchBarPlaceholder {

    static let beachOrResort = "해변, 해수욕장 이름을 검색해주세요."
    static let beachName = "해변 이름으로 검색"
}
