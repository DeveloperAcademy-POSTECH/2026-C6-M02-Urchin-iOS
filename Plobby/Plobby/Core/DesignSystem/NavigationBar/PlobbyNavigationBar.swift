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
    let isBackEnabled: Bool
    let trailingButton: PlobbyNavigationBarConfiguration.TrailingButton?

    init(
        title: String? = nil,
        style: Style,
        isBackEnabled: Bool = true,
        isTrailingEnabled: Bool = true,
        onBack: @escaping () -> Void,
        trailingAction: @escaping () -> Void,
        @ViewBuilder trailingLabel: () -> TrailingLabel
    ) {
        self.title = title
        self.style = style
        self.onBack = onBack
        self.isBackEnabled = isBackEnabled
        self.trailingButton = PlobbyNavigationBarConfiguration.TrailingButton(
            action: trailingAction,
            label: AnyView(trailingLabel()),
            isEnabled: isTrailingEnabled
        )
    }

    // MARK: - Body

    var body: some View {
        style.makeBody(
            configuration: PlobbyNavigationBarConfiguration(
                title: title.map {
                    PlobbyNavigationBarConfiguration.Title(text: $0)
                },
                backButton: PlobbyNavigationBarConfiguration.BackButton(action: onBack, isEnabled: isBackEnabled),
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
        isBackEnabled: Bool = true,
        onBack: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.onBack = onBack
        self.isBackEnabled = isBackEnabled
        self.trailingButton = nil
    }
}

extension PlobbyNavigationBar where Style == CenteredPlobbyNavigationBarStyle {

    init(
        title: String? = nil,
        isBackEnabled: Bool = true,
        isTrailingEnabled: Bool = true,
        onBack: @escaping () -> Void,
        trailingAction: @escaping () -> Void,
        @ViewBuilder trailingLabel: () -> TrailingLabel
    ) {
        self.init(
            title: title,
            style: .centered,
            isBackEnabled: isBackEnabled,
            isTrailingEnabled: isTrailingEnabled,
            onBack: onBack,
            trailingAction: trailingAction,
            trailingLabel: trailingLabel
        )
    }
}

extension PlobbyNavigationBar where Style == CenteredPlobbyNavigationBarStyle, TrailingLabel == EmptyView {

    init(
        title: String? = nil,
        isBackEnabled: Bool = true,
        onBack: @escaping () -> Void
    ) {
        self.init(
            title: title,
            style: .centered,
            isBackEnabled: isBackEnabled,
            onBack: onBack
        )
    }
}

// MARK: - Style

/// 생성자에서 style 파라미터를 .centered, .leading으로 간단히 사용하기 위함
extension PlobbyNavigationBarStyle where Self == CenteredPlobbyNavigationBarStyle {

    static var centered: Self { CenteredPlobbyNavigationBarStyle() }
}

extension PlobbyNavigationBarStyle where Self == LeadingPlobbyNavigationBarStyle {

    static var leading: Self { LeadingPlobbyNavigationBarStyle() }
}
