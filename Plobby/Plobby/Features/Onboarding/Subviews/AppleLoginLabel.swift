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
        HStack(spacing: 16.scaled) {
            Image(systemName: "apple.logo")
                .font(.system(size: 18.scaled, weight: .semibold))

            Text("Apple로 로그인")
                .plobbyFont(.cardTitle)
        }
        .foregroundStyle(Color(.gray0))
        .frame(maxWidth: .infinity)
        .frame(height: 56.scaled)
        .background(Color(.neutralBlack), in: RoundedRectangle(cornerRadius: 8.scaled))
    }
}
