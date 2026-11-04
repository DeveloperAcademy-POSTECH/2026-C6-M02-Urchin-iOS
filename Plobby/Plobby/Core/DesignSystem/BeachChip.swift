//
//  BeachChip.swift
//  Plobby
//
//  Created by 이은지 on 11/4/26.
//

import SwiftUI

// TODO: 추후 디자인 시스템에 맞게 색상 수정
struct BeachChip: View {

    // MARK: - Properties

    let title: String
    let systemImage: String
    var iconColor: Color = .green
    var textColor: Color = .black

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(iconColor)

            Text(title)
                .foregroundStyle(textColor)
        }
        .font(.system(size: 15, weight: .medium))
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(Color.gray.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        }
    }
}
