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
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case profileResponse(Result<Profile?, any Error>)
        case favoriteBeachesResponse(Result<[Beach], any Error>)
        case recordsResponse(Result<[RecordSummary], any Error>)
        case profileEditButtonTapped
        case settingsButtonTapped
        case favoriteBeachManageButtonTapped
        case favoriteBeachTapped(Beach)
        case recordFilterChanged(RecordFilter)
        case recordTapped(RecordSummary.ID)
        case appleLoginButtonTapped
        case profileEdit(PresentationAction<ProfileEditFeature.Action>)
        case settings(PresentationAction<SettingsFeature.Action>)
        case recordDetail(PresentationAction<RecordDetailFeature.Action>)
        case beachHome(PresentationAction<BeachHomeFeature.Action>)
        case beachRecordDetail(PresentationAction<RecordDetailFeature.Action>)
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

            case .favoriteBeachManageButtonTapped:
                return .none

            case let .favoriteBeachTapped(beach):
                state.beachHome = BeachHomeFeature.State(beach: beach)
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

            case .profileEdit, .settings, .recordDetail, .beachHome, .beachRecordDetail, .delegate:
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
}
