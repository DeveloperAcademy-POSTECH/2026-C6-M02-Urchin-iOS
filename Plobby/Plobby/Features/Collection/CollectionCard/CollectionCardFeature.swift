//
//  CollectionCardFeature.swift
//  Plobby
//
//  Created by 이은지 on 11/6/26.
//

import ComposableArchitecture

@Reducer
struct CollectionCardFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable, Identifiable {
        let category: TrashCategory
        var collectedCount: Int
        var nickname: String?
        var isFlipped = false

        var id: TrashCategory { category }
    }

    // MARK: - Action

    enum Action {
        case flipButtonTapped
        case recordButtonTapped
        case delegate(Delegate)

        enum Delegate {
            case recordStartRequested
        }
    }

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .flipButtonTapped:
                state.isFlipped.toggle()
                return .none

            case .recordButtonTapped:
                return .send(.delegate(.recordStartRequested))

            case .delegate:
                return .none
            }
        }
    }
}
