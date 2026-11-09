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
        var toast = ToastFeature.State()
        @Presents var profileEdit: ProfileEditFeature.State?
        @Presents var settings: SettingsFeature.State?
        @Presents var recordDetail: RecordDetailFeature.State?
        @Presents var beachHome: BeachHomeFeature.State?
        /// 해변 홈에서 연 기록 상세예요. 마이 목록에서 연 상세와 화면 단계가 달라서 따로 둬요.
        @Presents var beachRecordDetail: RecordDetailFeature.State?

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
            favoriteBeaches.count >= HomeFeature.maximumFavoriteBeachCount
        }
    }

    /// 되돌리기를 누르면 원래 자리로 돌려놓기 위해 해제한 위치를 함께 둬요.
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
        case profileEditButtonTapped
        case settingsButtonTapped
        case favoriteBeachAddButtonTapped
        case favoriteBeachTapped(Beach)
        case favoriteBeachUnfavoriteButtonTapped(Beach)
        case favoriteBeachUndoButtonTapped
        case favoriteBeachRequestFailed(Beach, isFavorite: Bool)
        case recordFilterChanged(RecordFilter)
        case recordTapped(RecordSummary.ID)
        case appleLoginButtonTapped
        case profileEdit(PresentationAction<ProfileEditFeature.Action>)
        case settings(PresentationAction<SettingsFeature.Action>)
        case recordDetail(PresentationAction<RecordDetailFeature.Action>)
        case beachHome(PresentationAction<BeachHomeFeature.Action>)
        case beachRecordDetail(PresentationAction<RecordDetailFeature.Action>)
        case toast(ToastFeature.Action)
        case delegate(Delegate)

        enum Delegate {
            case loginRequired
            case signInRequested
            case signedOut
        }
    }

    // MARK: - Dependency

    @Dependency(\.userClient) var userClient
    @Dependency(\.beachClient) var beachClient
    @Dependency(\.recordClient) var recordClient

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Scope(state: \.toast, action: \.toast) {
            ToastFeature()
        }

        Reduce { state, action in
            switch action {
            case .onAppear:
                guard case let .member(user) = state.membershipStatus else { return .none }

                return .merge(
                    fetchMyProfile(),
                    fetchFavoriteBeaches(),
                    fetchRecords(userID: user.id)
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

            case let .profileResponse(.failure(error)),
                 let .favoriteBeachesResponse(.failure(error)),
                 let .recordsResponse(.failure(error)):
                PlobbyLogger.error(error)
                return .none

            // TODO: 관심 해변 추가 화면 연결 (별도 이슈에서 구현)
            case .favoriteBeachAddButtonTapped:
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
                    .send(.toast(.show("관심 해변을 해제했어요")))
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
                return .send(.toast(.show(isFavorite ? "관심 해변을 되돌리지 못했어요" : "관심 해변을 해제하지 못했어요")))

            case .toast(.toastDismissed):
                state.removedFavoriteBeach = nil
                return .none

            case let .recordFilterChanged(filter):
                state.recordFilter = filter
                return .none

            case let .recordTapped(recordID):
                state.recordDetail = RecordDetailFeature.State(recordID: recordID)
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

            // 로그인은 MainTab의 SignInFeature가 처리해요
            case .appleLoginButtonTapped:
                return .send(.delegate(.signInRequested))

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

            case .beachRecordDetail(.presented(.delegate(.closed))),
                 .beachRecordDetail(.presented(.delegate(.deleted))):
                state.beachRecordDetail = nil
                return .none

            case let .beachRecordDetail(.presented(.delegate(.reported(recordID)))):
                state.beachRecordDetail = nil
                return .send(.beachHome(.presented(.recordHidden(recordID))))

            case let .beachRecordDetail(.presented(.delegate(.blocked(userID)))):
                state.beachRecordDetail = nil
                return .send(.beachHome(.presented(.userBlocked(userID))))

            case .profileEdit, .settings, .recordDetail, .beachHome, .beachRecordDetail, .toast, .delegate:
                return .none
            }
        }
        .ifLet(\.$profileEdit, action: \.profileEdit) {
            ProfileEditFeature()
        }
        .ifLet(\.$settings, action: \.settings) {
            SettingsFeature()
        }
        .ifLet(\.$recordDetail, action: \.recordDetail) {
            RecordDetailFeature()
        }
        .ifLet(\.$beachHome, action: \.beachHome) {
            BeachHomeFeature()
        }
        .ifLet(\.$beachRecordDetail, action: \.beachRecordDetail) {
            RecordDetailFeature()
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
