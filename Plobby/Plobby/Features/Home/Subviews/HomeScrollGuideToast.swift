//
//  HomeScrollGuideToast.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import SwiftUI

/// 처음 홈에 들어왔을 때 장면을 스크롤해 보라고 알려주는 토스트예요.
struct HomeScrollGuideToast: View {

    var body: some View {
        HStack(spacing: 8.scaled) {
            Image(systemName: "arrow.down")
                .font(.system(size: 14.scaled, weight: .medium))
            Text("아래로 스크롤해 주세요")
                .plobbyFont(.label)
        }
        .foregroundStyle(Color(.gray0))
        .padding(.horizontal, 16.scaled)
        .padding(.vertical, 12.scaled)
        .background(Color(.neutralBlack).opacity(0.4), in: RoundedRectangle(cornerRadius: 12.scaled))
        .allowsHitTesting(false)
    }
}
