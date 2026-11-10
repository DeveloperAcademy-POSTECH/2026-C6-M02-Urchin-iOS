//
//  LeadingPlobbyNavigationBarStyle.swift
//  Plobby
//
//  Created by 더스틴 on 11/10/26.
//

import SwiftUI

struct LeadingPlobbyNavigationBarStyle: PlobbyNavigationBarStyle {

    func makeBody(configuration: PlobbyNavigationBarConfiguration) -> some View {
        HStack(spacing: 0) {
            configuration.backButton

            configuration.title

            Spacer(minLength: 8.scaled)

            configuration.trailingButton
        }
        .padding(.horizontal, 12.scaled)
    }
}
