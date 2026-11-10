//
//  RecordCollectingFeature.swift
//  Plobby
//
//  Created by 이은지 on 11/10/26.
//

import Foundation

import ComposableArchitecture

/// 기록 저장 직후 보상 화면 전에 보여주는 "쓰레기를 모으는 중" 화면이에요
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
                // ponytail: 애니메이션이 정해지기 전까지 고정 시간 뒤 넘어가요. 애니메이션이 끝나는 시점으로 바꿔야 해요
                return .run { send in
                    try await clock.sleep(for: .seconds(2))
                    await send(.delegate(.finished))
                }

            case .delegate:
                return .none
            }
        }
    }
}
