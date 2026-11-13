//
//  PlobbyNavigationBarConfiguration.swift
//  Plobby
//
//  Created by 더스틴 on 11/10/26.
//

import SwiftUI

struct PlobbyNavigationBarConfiguration {

    let title: Title?
    let backButton: BackButton
    let trailingButtons: [TrailingButton]

    /// 오른쪽 버튼들을 순서대로 붙여서 보여줘요.
    var trailingButtonGroup: some View {
        HStack(spacing: 0) {
            ForEach(trailingButtons.indices, id: \.self) { index in
                trailingButtons[index]
            }
        }
    }

    struct Title: View {

        let text: String

        var body: some View {
            Text(text)
                .plobbyFont(.cardTitle)
                .foregroundStyle(Color(.textPrimary))
                .lineLimit(1)
        }
    }

    struct BackButton: View {

        let action: () -> Void
        var isEnabled = true

        var body: some View {
            Button(action: action) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18.scaled, weight: .semibold))
                    .foregroundStyle(Color(.textPrimary))
                    .frame(width: 44.scaled, height: 44.scaled)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
            .accessibilityLabel("뒤로")
        }
    }

    struct TrailingButton: View {

        let action: () -> Void
        let label: AnyView
        var isEnabled = true

        var body: some View {
            Button(action: action) {
                label
                    .frame(minWidth: 44.scaled, minHeight: 44.scaled)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
        }
    }
}
