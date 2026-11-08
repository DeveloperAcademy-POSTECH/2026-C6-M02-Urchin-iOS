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
    struct State: Equatable {
        var selectedCategory: TrashCategory = .plastic
        // TODO: 컬렉션 데이터 연동 후 실제 개수로 교체
        var collectedCounts: [TrashCategory: Int] = [
            .plastic: 128, .glass: 12, .metal: 4, .fishingGear: 19,
            .styrofoam: 8, .can: 17, .rubber: 3, .etc: 3
        ]
        // TODO: 프로필 연동 후 실제 닉네임으로 교체
        var nickname: String?
        var isFlipped = false

        var collectedCount: Int {
            collectedCounts[selectedCategory, default: 0]
        }
    }

    // MARK: - Action

    enum Action {
        case categorySelected(TrashCategory)
        case flipButtonTapped
    }

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .categorySelected(category):
                state.selectedCategory = category
                return .none

            case .flipButtonTapped:
                state.isFlipped.toggle()
                return .none
            }
        }
    }
}
