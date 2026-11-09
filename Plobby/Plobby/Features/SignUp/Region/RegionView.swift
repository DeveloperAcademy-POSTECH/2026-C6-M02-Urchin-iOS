//
//  RegionView.swift
//  Plobby
//
//  Created by 이은지 on 10/31/26.
//

import SwiftUI

import ComposableArchitecture

struct RegionView: View {
    
    // MARK: - Properties
    
    let store: StoreOf<RegionFeature>
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            progressBar
            titleSection
            BeachPicker(store: store.scope(state: \.picker, action: \.picker))
            nextButton
        }
    }
}

// MARK: - 상단 (진행 바, 제목)

private extension RegionView {
    
    var progressBar: some View {
        SignUpProgressBar(currentStep: 2, totalSteps: 2)
            .padding(.top, 23.scaled)
            .padding(.bottom, 31.scaled)
            .padding(.horizontal, 20.scaled)
    }
    
    var titleSection: some View {
        VStack(alignment: .leading, spacing: 8.scaled) {
            Text("관심 해변을 골라 주세요")
                .plobbyFont(.heading)
                .foregroundStyle(Color(.textPrimary))

            Text("최대 3개까지 고르고, 마이페이지에서 바꿀 수 있어요")
                .plobbyFont(.body)
                .foregroundStyle(Color(.textSecondary))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20.scaled)
    }
}

// MARK: - Subviews

extension RegionView {
    private var nextButton: some View {
        PlobbyButton(text: "다음") {
            store.send(.nextButtonTapped)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Preview

#Preview {
    // 미리보기용 해변 목록을 넣어요 (미리보기에서는 파일이 아니라 메모리에 저장돼요)
    let _ = {
        @Shared(.beaches) var beaches
        $beaches.withLock {
            $0 = [
                Beach(id: UUID(), region: .east, name: "영일대 해수욕장", address: "경북 포항시", latitude: 0, longitude: 0),
                Beach(id: UUID(), region: .south, name: "해운대 해수욕장", address: "부산 해운대구", latitude: 0, longitude: 0),
                Beach(id: UUID(), region: .west, name: "대천 해수욕장", address: "충남 보령시", latitude: 0, longitude: 0),
                Beach(id: UUID(), region: .jeju, name: "협재 해수욕장", address: "제주 제주시", latitude: 0, longitude: 0)
            ]
        }
    }()

    NavigationStack {
        RegionView(
            store: Store(initialState: RegionFeature.State()) {
                RegionFeature()
            }
        )
        .plobbyNavigationTitle("회원가입")
    }
}
