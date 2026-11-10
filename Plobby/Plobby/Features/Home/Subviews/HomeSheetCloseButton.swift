//
//  HomeSheetCloseButton.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import SwiftUI

/// 시트·팝업 오른쪽 위 닫기 버튼이에요.
struct HomeSheetCloseButton: View {

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 16.scaled, weight: .semibold))
                .foregroundStyle(Color(.textPrimary))
                .frame(width: 44.scaled, height: 44.scaled)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("닫기")
    }
}
