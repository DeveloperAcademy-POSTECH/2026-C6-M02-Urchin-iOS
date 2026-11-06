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
        @Presents var favoriteBeachPicker: RegionFeature.State?
        
        var currentBanner: RecordType = .plobbing
        var favoriteBeaches: [Beach] = []
        var recentRecords: [RecordSummary] = []

        var canAddFavoriteBeach: Bool {
            favoriteBeaches.count < HomeFeature.maximumFavoriteBeachCount
        }

        var recentRecordCards: [RecordSummary] {
            Array(recentRecords.prefix(HomeFeature.recentRecordCardCount))
        }

        var recentRecordRows: [RecordSummary] {
            Array(recentRecords.dropFirst(HomeFeature.recentRecordCardCount))
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
        case moreRecentRecordsButtonTapped
        case dailyTipBannerTapped
        case recentRecordsResponse([RecordSummary])
        case favoriteBeachPicker(PresentationAction<RegionFeature.Action>)
        case delegate(Delegate)

        enum Delegate {
            case recordStarted(RecordType)
            case loginRequired
        }
    }

    // MARK: - Dependency

    @Dependency(\.recordClient) var recordClient

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            if case .guest = state.membershipStatus, action.isUserInteraction {
                return .send(.delegate(.loginRequired))
            }

            switch action {
            case .onAppear:
                return .merge(startTimer(), fetchRecentRecords())

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

            // TODO: 기록 목록 화면 이동
            case .moreRecentRecordsButtonTapped:
                return .none

            // TODO: 하루 상식 상세 화면 이동
            case .dailyTipBannerTapped:
                return .none

            case let .recentRecordsResponse(records):
                state.recentRecords = records
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

// MARK: - Action

private extension HomeFeature.Action {

    var isUserInteraction: Bool {
        switch self {
        case .recordButtonTapped,
             .notificationButtonTapped,
             .addFavoriteBeachButtonTapped,
             .moreRecentRecordsButtonTapped,
             .dailyTipBannerTapped:
            true
        default:
            false
        }
    }
}

// MARK: - Functions

extension HomeFeature {

    static let banners: [RecordType] = [.plobbing, .plogging]
    static let maximumFavoriteBeachCount = 3
    static let recentRecordCardCount = 2
    private static let recentRecordLimit = 5

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

    private func fetchRecentRecords() -> Effect<Action> {
        .run { send in
            let records = try await recordClient.fetchRecords(0, HomeFeature.recentRecordLimit)
            await send(.recentRecordsResponse(records))
        } catch: { error, _ in
            PlobbyLogger.error(error)
        }
    }
}
