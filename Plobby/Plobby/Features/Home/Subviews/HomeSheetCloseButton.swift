//
//  HomeSheetCloseButton.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import SwiftUI

struct HomeSheetCloseButton: View {

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 16.scaled, weight: .semibold))
                .foregroundStyle(Color(.textPrimary))
                .padding(.trailing, CGFloat(-2.2).scaled)
                .frame(width: 44.scaled, height: 44.scaled, alignment: .trailing)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("닫기")
    }
}

