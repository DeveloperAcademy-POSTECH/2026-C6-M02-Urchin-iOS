//
//  SignUpProgressBar.swift
//  Plobby
//
//  Created by 이은지 on 11/9/26.
//

import SwiftUI

struct SignUpProgressBar: View {

    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 8.scaled) {
            ForEach(1...totalSteps, id: \.self) { step in
                Rectangle()
                    .fill(step <= currentStep ? Color(.brandPrimary) : Color(.borderDefault))
                    .frame(height: 4.scaled)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("회원가입 \(totalSteps)단계 중 \(currentStep)단계")
    }
}
