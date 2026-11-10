//
//  PlobbyNavigationBar.swift
//  Plobby
//
//  Created by 더스틴 on 11/9/26.
//

import SwiftUI

struct PlobbyNavigationBar<Style: PlobbyNavigationBarStyle, TrailingLabel: View>: View {

    // MARK: - Properties

    let title: String?
    let style: Style
    let onBack: () -> Void
    let trailingButton: PlobbyNavigationBarConfiguration.TrailingButton?

    init(
        title: String? = nil,
        style: Style,
        onBack: @escaping () -> Void,
        trailingAction: @escaping () -> Void,
        @ViewBuilder trailingLabel: () -> TrailingLabel
    ) {
        self.title = title
        self.style = style
        self.onBack = onBack
        self.trailingButton = PlobbyNavigationBarConfiguration.TrailingButton(
            action: trailingAction,
            label: AnyView(trailingLabel())
        )
    }

    // MARK: - Body

    var body: some View {
        style.makeBody(
            configuration: PlobbyNavigationBarConfiguration(
                title: title.map {
                    PlobbyNavigationBarConfiguration.Title(text: $0)
                },
                backButton: PlobbyNavigationBarConfiguration.BackButton(action: onBack),
                trailingButton: trailingButton
            )
        )
        .frame(height: 56.scaled)
    }
}

// MARK: - Initializers

extension PlobbyNavigationBar where TrailingLabel == EmptyView {

    init(
        title: String? = nil,
        style: Style,
        onBack: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.onBack = onBack
        self.trailingButton = nil
    }
}

extension PlobbyNavigationBar where Style == CenteredPlobbyNavigationBarStyle {

    init(
        title: String? = nil,
        onBack: @escaping () -> Void,
        trailingAction: @escaping () -> Void,
        @ViewBuilder trailingLabel: () -> TrailingLabel
    ) {
        self.init(
            title: title,
            style: .centered,
            onBack: onBack,
            trailingAction: trailingAction,
            trailingLabel: trailingLabel
        )
    }
}

extension PlobbyNavigationBar where Style == CenteredPlobbyNavigationBarStyle, TrailingLabel == EmptyView {

    init(
        title: String? = nil,
        onBack: @escaping () -> Void
    ) {
        self.init(
            title: title,
            style: .centered,
            onBack: onBack
        )
    }
}

// MARK: - Style

extension PlobbyNavigationBarStyle where Self == CenteredPlobbyNavigationBarStyle {

    static var centered: Self { CenteredPlobbyNavigationBarStyle() }
}

extension PlobbyNavigationBarStyle where Self == LeadingPlobbyNavigationBarStyle {

    static var leading: Self { LeadingPlobbyNavigationBarStyle() }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        PlobbyNavigationBar {}

        PlobbyNavigationBar(title: "활동 장소 선택") {}

        PlobbyNavigationBar(title: "기록 상세") {} trailingAction: {} trailingLabel: {
            Image(systemName: "ellipsis")
                .foregroundStyle(Color(.textPrimary))
        }

        PlobbyNavigationBar(title: "알림", style: .leading) {}

        PlobbyNavigationBar(title: "프로필 수정", style: .leading) {} trailingAction: {} trailingLabel: {
            Text("저장")
                .plobbyFont(.label)
                .foregroundStyle(Color(.textTertiary))
        }
    }
}
