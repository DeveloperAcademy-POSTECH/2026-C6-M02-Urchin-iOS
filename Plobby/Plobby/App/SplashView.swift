//
//  SplashView.swift
//  Plobby
//
//  Created by 이은지 on 11/13/26.
//

import SwiftUI

struct SplashView: View {
    
    // MARK: - Properties

    let onFinished: () -> Void

    private static let symbolSize = CGSize(width: 112, height: 100)
    private static let wordmarkWidth: CGFloat = 182
    private static let wordmarkHeight: CGFloat = wordmarkWidth * 23 / 73
    private static let wordmarkSpacing: CGFloat = 2
    private static let duration: TimeInterval = 1.3

    // MARK: - Body
    
    var body: some View {
        ZStack {
            Color(.gray0)
                .ignoresSafeArea()

            VStack(spacing: Self.wordmarkSpacing.scaled) {
                Image(.logo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Self.symbolSize.width.scaled, height: Self.symbolSize.height.scaled)

                Image(.homeLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Self.wordmarkWidth.scaled, height: Self.wordmarkHeight.scaled)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("plobby")
        }
        .task {
            try? await Task.sleep(for: .seconds(Self.duration))
            onFinished()
        }
    }
}
