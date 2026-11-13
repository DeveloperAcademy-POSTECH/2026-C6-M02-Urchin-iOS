//
//  CenteredPlobbyNavigationBarStyle.swift
//  Plobby
//
//  Created by 더스틴 on 11/10/26.
//

import SwiftUI

struct CenteredPlobbyNavigationBarStyle: PlobbyNavigationBarStyle {

    func makeBody(configuration: PlobbyNavigationBarConfiguration) -> some View {
        ZStack {
            if let title = configuration.title {
                title
                    .padding(.horizontal, 56.scaled)
            }

            HStack(spacing: 0) {
                configuration.backButton

                Spacer(minLength: 0)

                configuration.trailingButtonGroup
            }
            .padding(.horizontal, 12.scaled)
        }
    }
}
