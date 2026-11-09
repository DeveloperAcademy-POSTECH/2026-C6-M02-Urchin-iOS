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
            TermsAgreementView(store: store)
        } destination: { pathStore in
            switch pathStore.case {
            case .profile:
                SignUpProfileView(store: store)
                    .plobbyNavigationTitle("회원가입")

            case let .region(store):
                RegionView(store: store)
                    .plobbyNavigationTitle("회원가입")

            case let .complete(store):
                CompleteView(store: store)
            }
        }
        .fullScreenCover(item: $store.scope(state: \.photoPicker, action: \.photoPicker)) { store in
            PhotosPickerView(store: store)
        }
        .plobbyAlert($store.scope(state: \.alert, action: \.alert))
    }
}

// MARK: - Preview

#Preview("프로필 등록") {
    let store = Store(
        initialState: {
            var state = SignUpFeature.State(user: AuthUser(id: UUID(), email: nil))
            state.isAgeConfirmed = true
            state.isTermsAgreed = true
            state.isPrivacyAgreed = true
            return state
        }()
    ) {
        SignUpFeature()
    }
    let _ = store.send(.agreementNextButtonTapped)

    SignUpView(store: store)
}
