//
//  RecordCollectingFeature.swift
//  Plobby
//
//  Created by 이은지 on 11/10/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct RecordCollectingFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        let recordID: UUID
        let beachName: String?
        let trash: TrashSelection
        let weightKg: Double?
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case delegate(Delegate)

        @CasePathable
        enum Delegate {
            case finished
        }
    }

    // MARK: - Dependency

    @Dependency(\.continuousClock) var clock

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    try await clock.sleep(for: .seconds(3.5))
                    await send(.delegate(.finished))
                }

            case .delegate:
                return .none
            }
        }
    }
}
