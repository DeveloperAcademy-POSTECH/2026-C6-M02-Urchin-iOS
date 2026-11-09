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
        @Presents var recordDetail: RecordDetailFeature.State?
        @Presents var notification: NotificationFeature.State?
        
        var currentBanner: RecordType = .plobbing
        var recentRecords: [RecordSummary] = []

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
        case refreshPulled
        case timerTicked
        case bannerChanged(RecordType)
        case bannerDragStarted
        case bannerDragEnded
        case recordButtonTapped(RecordType)
        case notificationButtonTapped
        case recentRecordTapped(RecordSummary.ID)
        case dailyTipBannerTapped
        case recentRecordsResponse([RecordSummary])
        case recordDetail(PresentationAction<RecordDetailFeature.Action>)
        case notification(PresentationAction<NotificationFeature.Action>)
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

            case .refreshPulled:
                return fetchRecentRecords()

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

            case let .recordButtonTapped(recordType):
                return .send(.delegate(.recordStarted(recordType)))

            case .notificationButtonTapped:
                state.notification = NotificationFeature.State()
                return .none

            case let .recentRecordTapped(recordID):
                state.recordDetail = RecordDetailFeature.State(recordID: recordID)
                return .none

            case .recordDetail(.presented(.delegate(.closed))):
                state.recordDetail = nil
                return .none

            case let .recordDetail(.presented(.delegate(.deleted(recordID)))),
                let .recordDetail(.presented(.delegate(.reported(recordID)))):
                state.recordDetail = nil
                state.recentRecords.removeAll { $0.id == recordID }
                return .none

            case let .recordDetail(.presented(.delegate(.blocked(userID)))):
                state.recordDetail = nil
                state.recentRecords.removeAll { $0.userID == userID }
                return .none

            case .recordDetail:
                return .none

            case .notification:
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
        .ifLet(\.$recordDetail, action: \.recordDetail) {
            RecordDetailFeature()
        }
        .ifLet(\.$notification, action: \.notification) {
            NotificationFeature()
        }
    }
}

// MARK: - Action

private extension HomeFeature.Action {

    var isUserInteraction: Bool {
        switch self {
        case .recordButtonTapped,
             .notificationButtonTapped,
             .recentRecordTapped,
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
