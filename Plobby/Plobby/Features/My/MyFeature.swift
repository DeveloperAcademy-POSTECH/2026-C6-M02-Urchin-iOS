//
//  MyFeature.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct MyFeature {

    // MARK: - State 

    @ObservableState
    struct State: Equatable {
        @Shared(.membershipStatus) var membershipStatus
        @Shared(.favoriteBeaches) var favoriteBeaches
        var profile: Profile?
        var savedProfileImage: Data?
        var records: [RecordSummary] = []
        var recordFilter: RecordFilter = .all
        var removedFavoriteBeach: RemovedFavoriteBeach?
        var hasUnreadNotification = false
        var toast = ToastFeature.State()
        @Presents var profileEdit: ProfileEditFeature.State?
        @Presents var settings: SettingsFeature.State?
        @Presents var notification: NotificationFeature.State?
        @Presents var recordDetail: RecordDetailFeature.State?
        @Presents var recordMenu: RecordMenuFeature.State?
        @Presents var beachHome: BeachHomeFeature.State?
        @Presents var beachRecordDetail: RecordDetailFeature.State?
        @Presents var favoriteBeachAdd: FavoriteBeachAddFeature.State?

        var filteredRecords: [RecordSummary] {
            guard let recordType = recordFilter.recordType else { return records }

            return records.filter { $0.recordType == recordType }
        }

        var collectedTrashCount: Int {
            records.reduce(0) { $0 + $1.trashCount }
        }

        var collectedWeightKg: Double {
            records.reduce(0) { $0 + ($1.weightKg ?? 0) }
        }

        var isFavoriteBeachLimitReached: Bool {
            favoriteBeaches.count >= Beach.maximumFavoriteCount
        }

        var isMember: Bool {
            guard case .member = membershipStatus else { return false }

            return true
        }
    }

    struct RemovedFavoriteBeach: Equatable {
        let beach: Beach
        let index: Int
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case profileResponse(Result<Profile?, any Error>)
        case favoriteBeachesResponse(Result<[Beach], any Error>)
        case recordsResponse(Result<[RecordSummary], any Error>)
        case unreadNotificationResponse(Result<Bool, any Error>)
        case profileEditButtonTapped
        case settingsButtonTapped
        case notificationButtonTapped
        case favoriteBeachAddButtonTapped
        case favoriteBeachTapped(Beach)
        case favoriteBeachUnfavoriteButtonTapped(Beach)
        case favoriteBeachUndoButtonTapped
        case favoriteBeachRequestFailed(Beach, isFavorite: Bool)
        case recordFilterChanged(RecordFilter)
        case recordTapped(RecordSummary.ID)
        case recordMenuSelected(RecordSummary, RecordMenuFeature.Menu)
        case recordStartButtonTapped
        case profileEdit(PresentationAction<ProfileEditFeature.Action>)
        case settings(PresentationAction<SettingsFeature.Action>)
        case notification(PresentationAction<NotificationFeature.Action>)
        case recordDetail(PresentationAction<RecordDetailFeature.Action>)
        case recordMenu(PresentationAction<RecordMenuFeature.Action>)
        case beachHome(PresentationAction<BeachHomeFeature.Action>)
        case beachRecordDetail(PresentationAction<RecordDetailFeature.Action>)
        case favoriteBeachAdd(PresentationAction<FavoriteBeachAddFeature.Action>)
        case toast(ToastFeature.Action)
        case delegate(Delegate)

        enum Delegate {
            case loginRequired
            case signedOut
            /// 목표 달성 알림을 눌러 홈으로 돌아가요.
            case homeRequested
        }
    }

    // MARK: - Dependency

    @Dependency(\.userClient) var userClient
    @Dependency(\.beachClient) var beachClient
    @Dependency(\.recordClient) var recordClient
    @Dependency(\.notificationClient) var notificationClient

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Scope(state: \.toast, action: \.toast) {
            ToastFeature()
        }

        core
            .ifLet(\.$beachHome, action: \.beachHome) {
                BeachHomeFeature()
            }
            .ifLet(\.$beachRecordDetail, action: \.beachRecordDetail) {
                RecordDetailFeature()
            }
            .ifLet(\.$favoriteBeachAdd, action: \.favoriteBeachAdd) {
                FavoriteBeachAddFeature()
            }
    }

    private var core: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard case let .member(user) = state.membershipStatus else { return .none }

                return .merge(
                    fetchMyProfile(),
                    fetchFavoriteBeaches(),
                    fetchRecords(userID: user.id),
                    fetchHasUnreadNotification()
                )

            case let .profileResponse(.success(profile)):
                state.profile = profile
                return .none

            case let .favoriteBeachesResponse(.success(beaches)):
                state.$favoriteBeaches.withLock { $0 = beaches }
                return .none

            case let .recordsResponse(.success(records)):
                state.records = records
                return .none

            case let .unreadNotificationResponse(.success(hasUnread)):
                state.hasUnreadNotification = hasUnread
                return .none

            case let .profileResponse(.failure(error)),
                 let .favoriteBeachesResponse(.failure(error)),
                 let .recordsResponse(.failure(error)),
                 let .unreadNotificationResponse(.failure(error)):
                PlobbyLogger.error(error)
                return .none

            case .favoriteBeachAddButtonTapped:
                guard state.isMember else { return .send(.delegate(.loginRequired)) }

                state.favoriteBeachAdd = FavoriteBeachAddFeature.State()
                return .none

            case let .favoriteBeachTapped(beach):
                state.beachHome = BeachHomeFeature.State(beach: beach)
                return .none

            case let .favoriteBeachUnfavoriteButtonTapped(beach):
                guard let index = state.favoriteBeaches.firstIndex(where: { $0.id == beach.id }) else { return .none }

                state.$favoriteBeaches.withLock { _ = $0.remove(at: index) }
                state.removedFavoriteBeach = RemovedFavoriteBeach(beach: beach, index: index)
                return .merge(
                    requestFavoriteBeach(beach, isFavorite: false),
                    .send(.toast(.show(.favoriteBeachRemoved)))
                )

            case .favoriteBeachUndoButtonTapped:
                guard let removedFavoriteBeach = state.removedFavoriteBeach else { return .none }

                state.removedFavoriteBeach = nil
                restoreFavoriteBeach(removedFavoriteBeach, in: state.$favoriteBeaches)
                return .merge(
                    requestFavoriteBeach(removedFavoriteBeach.beach, isFavorite: true),
                    .send(.toast(.toastDismissed))
                )

            case let .favoriteBeachRequestFailed(beach, isFavorite):
                state.removedFavoriteBeach = nil
                FavoriteBeachToggle.revert(beach, isFavorite: isFavorite, in: state.$favoriteBeaches)
                return .send(.toast(.show(isFavorite ? .favoriteBeachRestoreFailed : .favoriteBeachRemoveFailed)))

            case .toast(.toastDismissed):
                state.removedFavoriteBeach = nil
                return .none

            case let .recordFilterChanged(filter):
                state.recordFilter = filter
                return .none

            case let .recordTapped(recordID):
                state.recordDetail = RecordDetailFeature.State(recordID: recordID)
                return .none

            case let .recordMenuSelected(record, menu):
                state.recordMenu = RecordMenuFeature.State(record: record)
                return .send(.recordMenu(.presented(.menuSelected(menu))))

            case .recordMenu(.presented(.delegate(.updated))):
                state.recordMenu = nil

                guard case let .member(user) = state.membershipStatus else { return .none }

                return fetchRecords(userID: user.id)

            case let .recordMenu(.presented(.delegate(.deleted(recordID)))):
                state.recordMenu = nil
                state.records.removeAll { $0.id == recordID }
                return .none

            case .recordMenu(.presented(.delegate(.blocked))):
                state.recordMenu = nil
                return .none

            case .profileEditButtonTapped:
                guard case .member = state.membershipStatus else {
                    return .send(.delegate(.loginRequired))
                }
                guard let profile = state.profile else { return .none }

                state.profileEdit = ProfileEditFeature.State(profile: profile)
                return .none

            case .settingsButtonTapped:
                guard case .member = state.membershipStatus else {
                    return .send(.delegate(.loginRequired))
                }

                state.settings = SettingsFeature.State()
                return .none

            case .notificationButtonTapped:
                state.notification = NotificationFeature.State()
                return .none

            case .notification(.presented(.delegate(.homeRequested))):
                state.notification = nil
                return .send(.delegate(.homeRequested))

            case .notification(.presented(.delegate(.settingsRequested))):
                state.notification = nil
                state.settings = SettingsFeature.State()
                return .none

            case .recordStartButtonTapped:
                return .send(.delegate(.loginRequired))

            case let .profileEdit(.presented(.delegate(.saved(profile, profileImage)))):
                state.profile = profile

                if let profileImage {
                    state.savedProfileImage = profileImage
                }
                return .none

            case .settings(.presented(.delegate(.signedOut))):
                state.settings = nil
                return .send(.delegate(.signedOut))

            case .recordDetail(.presented(.delegate(.closed))):
                state.recordDetail = nil

                guard case let .member(user) = state.membershipStatus else { return .none }

                return fetchRecords(userID: user.id)

            case let .recordDetail(.presented(.delegate(.deleted(recordID)))):
                state.recordDetail = nil
                state.records.removeAll { $0.id == recordID }
                return .none

            case let .beachHome(.presented(.delegate(.recordSelected(record)))):
                state.beachRecordDetail = RecordDetailFeature.State(recordID: record.id)
                return .none

            case .beachRecordDetail(.presented(.delegate(.closed))):
                state.beachRecordDetail = nil
                return .none

            case let .beachRecordDetail(.presented(.delegate(.deleted(recordID)))):
                state.beachRecordDetail = nil
                state.records.removeAll { $0.id == recordID }
                return .send(.beachHome(.presented(.recordRemoved(recordID))))

            case let .beachRecordDetail(.presented(.delegate(.blocked(userID)))):
                state.beachRecordDetail = nil
                return .send(.beachHome(.presented(.userBlocked(userID))))

            case .profileEdit, .settings, .notification, .recordDetail, .recordMenu, .beachHome, .beachRecordDetail,
                 .favoriteBeachAdd, .toast, .delegate:
                return .none
            }
        }
        .ifLet(\.$profileEdit, action: \.profileEdit) {
            ProfileEditFeature()
        }
        .ifLet(\.$settings, action: \.settings) {
            SettingsFeature()
        }
        .ifLet(\.$notification, action: \.notification) {
            NotificationFeature()
        }
        .ifLet(\.$recordDetail, action: \.recordDetail) {
            RecordDetailFeature()
        }
        .ifLet(\.$recordMenu, action: \.recordMenu) {
            RecordMenuFeature()
        }
    }
}

// MARK: - Functions

extension MyFeature {

    private func fetchMyProfile() -> Effect<Action> {
        .run { send in
            await send(.profileResponse(Result { try await userClient.fetchMyProfile() }))
        }
    }

    private func fetchFavoriteBeaches() -> Effect<Action> {
        .run { send in
            await send(.favoriteBeachesResponse(Result { try await beachClient.fetchFavoriteBeaches() }))
        }
    }

    private func fetchRecords(userID: UUID) -> Effect<Action> {
        .run { send in
            await send(.recordsResponse(Result { try await recordClient.fetchUserRecords(userID) }))
        }
    }

    private func fetchHasUnreadNotification() -> Effect<Action> {
        .run { send in
            await send(.unreadNotificationResponse(Result { try await notificationClient.fetchHasUnread() }))
        }
    }

    private func requestFavoriteBeach(_ beach: Beach, isFavorite: Bool) -> Effect<Action> {
        .run { send in
            do {
                try await FavoriteBeachToggle.request(beach, isFavorite: isFavorite, beachClient: beachClient)
            } catch {
                PlobbyLogger.error(error)
                await send(.favoriteBeachRequestFailed(beach, isFavorite: isFavorite))
            }
        }
    }

    private func restoreFavoriteBeach(_ removed: RemovedFavoriteBeach, in favoriteBeaches: Shared<[Beach]>) {
        favoriteBeaches.withLock {
            guard !$0.contains(where: { $0.id == removed.beach.id }) else { return }

            $0.insert(removed.beach, at: min(removed.index, $0.count))
        }
    }
}
