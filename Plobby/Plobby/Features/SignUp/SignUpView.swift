//
//  SignUpView.swift
//  Plobby
//
//  Created by 이은지 on 10/30/26.
//

import SwiftUI

import ComposableArchitecture

struct SignUpView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<SignUpFeature>
    
    // MARK: - Body

    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            // 1. 약관 동의 (시작 화면)
            TermsAgreementView(store: store.scope(state: \.termsAgreement, action: \.termsAgreement))
        } destination: { pathStore in
            switch pathStore.case {
            // 2. 프로필 설정
            case let .profileSetup(store):
                ProfileSetupView(store: store)
                    .plobbyNavigationTitle("회원가입")

            // 3. 관심 해변 설정
            case let .favoriteBeachSetup(store):
                FavoriteBeachSetupView(store: store)
                    .plobbyNavigationTitle("회원가입")

            // 4. 회원가입 완료
            case let .complete(store):
                SignUpCompleteView(store: store)
            }
        }
        .plobbyAlert($store.scope(state: \.alert, action: \.alert))
    }
}

// MARK: - Preview

#Preview {
    SignUpView(
        store: Store(initialState: SignUpFeature.State(user: AuthUser(id: UUID(), email: nil))) {
            SignUpFeature()
        }
    )
}
