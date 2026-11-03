//
//  HomeFeature.swift
//  Plobby
//
//  Created by 이은지 on 11/1/26.
//

import SwiftUI

import ComposableArchitecture

@Reducer
struct HomeFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        let status: MembershipStatus
        var currentBanner: RecordType = .plobbing
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case onDisappear
        case timerTicked
        case bannerChanged(RecordType)
        case bannerDragStarted
        case bannerDragEnded
        case recordButtonTapped
        case notificationButtonTapped
        case delegate(Delegate)

        enum Delegate {
            case recordStarted(RecordType)
        }
    }

    // MARK: - Dependency

    @Dependency(\.continuousClock) var clock

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return startTimer()

            case .onDisappear:
                return .cancel(id: CancelID.timer)

            case .timerTicked:
                state.currentBanner = HomeFeature.nextBanner(after: state.currentBanner)
                return .none

            case let .bannerChanged(banner):
                if banner != state.currentBanner {
                    state.currentBanner = banner
                }
                return .none

            case .bannerDragStarted:
                return .cancel(id: CancelID.timer)

            case .bannerDragEnded:
                return startTimer()

            case .recordButtonTapped:
                return .send(.delegate(.recordStarted(state.currentBanner)))

            // TODO: 알림 화면 이동
            case .notificationButtonTapped:
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - Functions

extension HomeFeature {

    static let banners: [RecordType] = [.plobbing, .plogging]

    private nonisolated enum CancelID {
        case timer
    }

    private static let bannerInterval: Duration = .seconds(3)

    private static func nextBanner(after banner: RecordType) -> RecordType {
        let index = banners.firstIndex(of: banner) ?? 0
        return banners[(index + 1) % banners.count]
    }

    private func startTimer() -> Effect<Action> {
        .run { send in
            for await _ in await clock.timer(interval: HomeFeature.bannerInterval) {
                await send(.timerTicked, animation: .easeInOut)
            }
        }
        .cancellable(id: CancelID.timer, cancelInFlight: true)
    }
}
