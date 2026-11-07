//
//  SearchBar.swift
//  Plobby
//
//  Created by 이은지 on 11/7/26.
//

import SwiftUI

/// 해변 검색창 틀.
/// - 지도의 검색 버튼과 해변 검색 화면의 입력창이 같이 사용합니다.
/// - 왼쪽 아이콘(`leading`)과 내용(`content`)만 화면마다 다릅니다.
///
struct SearchBar<Leading: View, Content: View>: View {

    // MARK: - Properties

    @ViewBuilder let leading: Leading
    @ViewBuilder let content: Content

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8.scaled) {
            leading
                .frame(width: 24.scaled, height: 24.scaled)

            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12.scaled)
        .frame(height: 56.scaled)
        .background(Color(.gray0), in: RoundedRectangle(cornerRadius: 12.scaled))
    }
}

// MARK: - Constants

enum SearchBarText {

    static let placeholder = "해변, 해수욕장 이름을 검색해주세요."
}
