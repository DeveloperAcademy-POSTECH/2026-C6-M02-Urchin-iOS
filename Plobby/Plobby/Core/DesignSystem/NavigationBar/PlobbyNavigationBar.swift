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
    let trailingButtons: [PlobbyNavigationBarConfiguration.TrailingButton]

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
        self.trailingButtons = [
            PlobbyNavigationBarConfiguration.TrailingButton(
                action: trailingAction,
                label: AnyView(trailingLabel()),
                isEnabled: isTrailingEnabled
            )
        ]
    }

    // MARK: - Body

    var body: some View {
        style.makeBody(
            configuration: PlobbyNavigationBarConfiguration(
                title: title.map {
                    PlobbyNavigationBarConfiguration.Title(text: $0)
                },
                backButton: PlobbyNavigationBarConfiguration.BackButton(action: onBack, isEnabled: isBackEnabled),
                trailingButtons: trailingButtons
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
        self.trailingButtons = []
    }

    /// 오른쪽에 버튼을 여러 개 둘 때 써요.
    init(
        title: String? = nil,
        style: Style,
        isBackEnabled: Bool = true,
        onBack: @escaping () -> Void,
        trailingButtons: [PlobbyNavigationBarConfiguration.TrailingButton]
    ) {
        self.title = title
        self.style = style
        self.onBack = onBack
        self.isBackEnabled = isBackEnabled
        self.trailingButtons = trailingButtons
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

    init(
        title: String? = nil,
        isBackEnabled: Bool = true,
        onBack: @escaping () -> Void,
        trailingButtons: [PlobbyNavigationBarConfiguration.TrailingButton]
    ) {
        self.init(
            title: title,
            style: .centered,
            isBackEnabled: isBackEnabled,
            onBack: onBack,
            trailingButtons: trailingButtons
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
