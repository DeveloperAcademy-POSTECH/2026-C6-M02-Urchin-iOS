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
        var collectedCount: Int = 128
        // TODO: 프로필 연동 후 실제 닉네임으로 교체
        var nickname: String?
        var isFlipped = false
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
