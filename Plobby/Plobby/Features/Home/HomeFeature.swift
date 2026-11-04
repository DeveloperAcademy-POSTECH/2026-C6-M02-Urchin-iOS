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
        @Shared(.membershipStatus) var membershipStatus
        var currentBanner: RecordType = .plobbing
        var favoriteBeaches: [Beach] = []
        @Presents var favoriteBeachPicker: RegionFeature.State?

        var canAddFavoriteBeach: Bool {
            favoriteBeaches.count < HomeFeature.maximumFavoriteBeachCount
        }
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
        case addFavoriteBeachButtonTapped
        case favoriteBeachPicker(PresentationAction<RegionFeature.Action>)
        case delegate(Delegate)

        enum Delegate {
            case recordStarted(RecordType)
        }
    }

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

            case .addFavoriteBeachButtonTapped:
                state.favoriteBeachPicker = RegionFeature.State(
                    selectedBeachIDs: Set(state.favoriteBeaches.map(\.id))
                )
                return .none

            // TODO: BeachClient로 관심 해변 추가/삭제 요청
            case .favoriteBeachPicker(.presented(.nextButtonTapped)):
                guard let picker = state.favoriteBeachPicker else { return .none }

                state.favoriteBeaches = picker.allBeaches.filter { picker.selectedBeachIDs.contains($0.id) }
                state.favoriteBeachPicker = nil
                return .none

            case .favoriteBeachPicker:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$favoriteBeachPicker, action: \.favoriteBeachPicker) {
            RegionFeature()
        }
    }
}

// MARK: - Functions

extension HomeFeature {

    static let banners: [RecordType] = [.plobbing, .plogging]
    static let maximumFavoriteBeachCount = 3

    private nonisolated enum CancelID {
        case timer
    }

    private static let bannerInterval: Duration = .seconds(3)

    private static func nextBanner(after banner: RecordType) -> RecordType {
        let index = banners.firstIndex(of: banner) ?? 0
        return banners[(index + 1) % banners.count]
    }

    private func startTimer() -> Effect<Action> {
        .timer(
            id: CancelID.timer,
            interval: HomeFeature.bannerInterval,
            action: .timerTicked,
            animation: .easeInOut
        )
    }
}
