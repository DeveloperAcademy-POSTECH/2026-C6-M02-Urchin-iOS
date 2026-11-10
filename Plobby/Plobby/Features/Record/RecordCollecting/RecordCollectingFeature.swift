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
        case coverFinished
        case delegate(Delegate)

        @CasePathable
        enum Delegate {
            case finished
        }
    }

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .coverFinished:
                return .send(.delegate(.finished))

            case .delegate:
                return .none
            }
        }
    }
}
