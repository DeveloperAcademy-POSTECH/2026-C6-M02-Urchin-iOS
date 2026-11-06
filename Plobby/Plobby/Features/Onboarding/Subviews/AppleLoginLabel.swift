//
//  AppleLoginLabel.swift
//  Plobby
//
//  Created by 이은지 on 10/30/26.
//

import SwiftUI

struct AppleLoginLabel: View {

    // MARK: - Body

    var body: some View {
        label
            .font(.system(size: 18.scaled, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 51.scaled)
            .background(.black, in: RoundedRectangle(cornerRadius: 8.scaled))
    }
}

// MARK: - Subviews

extension AppleLoginLabel {

    private var label: some View {
        HStack(alignment: .center, spacing: 16.scaled) {
            Image(systemName: "applelogo")

            Text("Apple로 로그인")
        }
    }
}
