//
//  NotificationFeature.swift
//  Plobby
//
//  Created by dlsundn on 11/6/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct NotificationFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var notifications: [AppNotification] = []
        var isLoading = false
        @Presents var recordDetail: RecordDetailFeature.State?

        /// 푸시를 눌러 들어올 때는 기록 상세를 바로 열어요.
        init(recordDetail: RecordDetailFeature.State? = nil) {
            self.recordDetail = recordDetail
        }

        var isEmpty: Bool {
            !isLoading && notifications.isEmpty
        }

        var hasUnread: Bool {
            notifications.contains { !$0.isRead }
        }

        var todayNotifications: [AppNotification] {
            notifications.filter { Calendar.current.isDateInToday($0.createdAt) }
        }

        var earlierNotifications: [AppNotification] {
            notifications.filter { !Calendar.current.isDateInToday($0.createdAt) }
        }
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case refreshed
        case backButtonTapped
        case markAllAsReadButtonTapped
        case notificationTapped(AppNotification)
        case notificationsResponse(Result<[AppNotification], any Error>)
        case recordDetail(PresentationAction<RecordDetailFeature.Action>)
    }

    // MARK: - Dependency

    @Dependency(\.dismiss) var dismiss
    @Dependency(\.notificationClient) var notificationClient

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.notifications.isEmpty else { return .none }

                state.isLoading = true
                return fetchNotifications()

            case .refreshed:
                return fetchNotifications()

            case .backButtonTapped:
                return .run { _ in
                    await dismiss()
                }

            case .markAllAsReadButtonTapped:
                guard state.hasUnread else { return .none }

                for index in state.notifications.indices {
                    state.notifications[index].isRead = true
                }
                return updateAllReadAt()

            case let .notificationTapped(notification):
                if let index = state.notifications.firstIndex(where: { $0.id == notification.id }) {
                    state.notifications[index].isRead = true
                }

                let readEffect: Effect<Action> = notification.isRead ? .none : updateReadAt(notification)

                guard !notification.canReturnHome else {
                    return .merge(readEffect, .run { _ in await dismiss() })
                }

                if notification.canOpenRecord, let recordID = notification.recordID {
                    state.recordDetail = RecordDetailFeature.State(recordID: recordID)
                }
                return readEffect

            case let .notificationsResponse(.success(notifications)):
                state.isLoading = false
                state.notifications = notifications

                guard let recordID = state.recordDetail?.recordID else { return .none }

                let openedNotifications = notifications.filter { $0.recordID == recordID && !$0.isRead }
                for index in state.notifications.indices where state.notifications[index].recordID == recordID {
                    state.notifications[index].isRead = true
                }
                return .merge(openedNotifications.map(updateReadAt))

            case let .notificationsResponse(.failure(error)):
                PlobbyLogger.error(error)
                state.isLoading = false
                return .none

            case .recordDetail(.presented(.delegate(.closed))):
                state.recordDetail = nil
                return .none

            case .recordDetail(.presented(.delegate(.deleted))):
                state.recordDetail = nil
                return fetchNotifications()

            case .recordDetail:
                return .none
            }
        }
        .ifLet(\.$recordDetail, action: \.recordDetail) {
            RecordDetailFeature()
        }
    }
}

// MARK: - Functions

extension NotificationFeature {

    private func fetchNotifications() -> Effect<Action> {
        .run { send in
            await send(.notificationsResponse(Result {
                try await notificationClient.fetchNotifications()
            }))
        }
    }

    private func updateReadAt(_ notification: AppNotification) -> Effect<Action> {
        .run { _ in
            try await notificationClient.updateReadAt(notification)
        } catch: { error, _ in
            PlobbyLogger.error(error)
        }
    }

    private func updateAllReadAt() -> Effect<Action> {
        .run { _ in
            try await notificationClient.updateAllReadAt()
        } catch: { error, _ in
            PlobbyLogger.error(error)
        }
    }
}
