//
//  AppleLoginButton.swift
//  Plobby
//
//  Created by 이은지 on 10/30/26.
//

import SwiftUI

struct AppleLoginButton: View {

    // MARK: - Body

    var body: some View {
        label
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 51)
            .background(.black, in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Subviews

extension AppleLoginButton {

    private var label: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: "applelogo")

            Text("Apple로 로그인")
        }
    }
}
