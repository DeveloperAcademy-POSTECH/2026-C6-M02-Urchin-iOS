//
//  OnboardingPageIndicator.swift
//  Plobby
//
//  Created by 이은지 on 10/30/26.
//

import SwiftUI

struct OnboardingPageIndicator: View {
    
    // MARK: - Properties
    
    let currentIndex: Int
    let pageCount: Int

    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            indicator
        }
        .animation(.easeInOut(duration: 0.3), value: currentIndex)
    }
}

// MARK: - Subviews

extension OnboardingPageIndicator {
    
    private var indicator: some View {
        ForEach(0..<pageCount, id: \.self) { index in
            Capsule()
                .fill(index <= currentIndex ? Color.black : Color.gray.opacity(0.3))
                .frame(height: 4)
        }
    }
}
