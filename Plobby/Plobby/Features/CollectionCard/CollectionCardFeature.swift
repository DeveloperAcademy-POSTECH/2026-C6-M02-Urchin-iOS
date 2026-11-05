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
    }

    // MARK: - Action

    enum Action {
        case categoryButtonTapped
        case flipButtonTapped
    }

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            // TODO: 종류 선택 메뉴 연결
            case .categoryButtonTapped:
                return .none

            // TODO: 카드 뒷면 뒤집기 연결
            case .flipButtonTapped:
                return .none
            }
        }
    }
}
