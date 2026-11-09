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
        VStack {
            SignUpProgressBar(currentStep: 2, totalSteps: 2)
                .padding(.horizontal, 20.scaled)
                .padding(.bottom, 24.scaled)
            title
            subTitle
            RegionPicker(store: store)
            
            Spacer()
            
            nextButton
        }
    }
}

// MARK: - Subviews

extension RegionView {
    

    
    private var title: some View {
        Text("즐겨찾기에 넣을 해변을\n선택해주세요")
            .font(.system(size: 26, weight: .semibold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 21)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
    }
    
    private var subTitle: some View {
        Text("즐겨찾기에 넣을 해변은 마이페이지에서\n언제든 다시 바꿀 수 있어요")
            .font(.system(size: 14, weight: .regular))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 53)
    }
    
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
