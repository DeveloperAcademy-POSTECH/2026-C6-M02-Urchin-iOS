//
//  HomeActivityPicker.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import SwiftUI

/// "기록하기"를 누르면 뜨는 활동 선택 팝업이에요.
struct HomeActivityPicker: View {

    let onSelect: (RecordType) -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color(.neutralBlack).opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)
                .accessibilityLabel("닫기")
                .accessibilityAddTraits(.isButton)

            VStack(alignment: .leading, spacing: 8.scaled) {
                Text("기록할 활동을 골라주세요")
                    .plobbyFont(.heading)
                    .foregroundStyle(Color(.textPrimary))
                    .padding(.bottom, 4.scaled)

                ForEach([RecordType.plogging, .plobbing], id: \.self) { type in
                    row(type)
                }
            }
            .padding(.horizontal, 20.scaled)
            .padding(.top, 20.scaled)
            .padding(.bottom, 24.scaled)
            .background(Color(.gray0), in: RoundedRectangle(cornerRadius: 16.scaled))
            .padding(.horizontal, 24.scaled)
        }
    }

    private func row(_ type: RecordType) -> some View {
        Button {
            onSelect(type)
        } label: {
            HStack(spacing: 12.scaled) {
                Image(systemName: type.homeIconName)
                    .font(.system(size: 18.scaled, weight: .semibold))
                    .foregroundStyle(Color(.currentBrandText))
                    .frame(width: 24.scaled, height: 24.scaled)

                Text(type.title)
                    .plobbyFont(.actionLabel)
                    .foregroundStyle(Color(.textPrimary))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14.scaled, weight: .semibold))
                    .foregroundStyle(Color(.textSecondary))
            }
            .padding(16.scaled)
            .background(Color(.gray50), in: RoundedRectangle(cornerRadius: 12.scaled))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private extension RecordType {

    var homeIconName: String {
        switch self {
        case .plogging: "figure.run"
        case .plobbing: "water.waves"
        }
    }
}
