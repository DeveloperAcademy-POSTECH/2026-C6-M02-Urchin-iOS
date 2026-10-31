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
            VStack {
                Text("회원가입 화면이지롱")

                Button("다음") {
                    store.send(.nextButtonTapped)
                }
            }
        } destination: { store in
            switch store.case {
            case let .region(store):
                RegionView(store: store)

            case let .complete(store):
                CompleteView(store: store)
            }
        }
    }
}
