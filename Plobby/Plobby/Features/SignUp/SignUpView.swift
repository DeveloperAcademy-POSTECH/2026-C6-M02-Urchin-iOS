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
            TermsAgreementView(store: store.scope(state: \.termsAgreement, action: \.termsAgreement))
        } destination: { pathStore in
            switch pathStore.case {
            case let .profileSetup(store):
                ProfileSetupView(store: store)

            case let .favoriteBeachSetup(store):
                FavoriteBeachSetupView(store: store)

            case let .complete(store):
                SignUpCompleteView(store: store)
            }
        }
        .plobbyAlert(store: store, state: \.alert, action: \.alert)
    }
}
