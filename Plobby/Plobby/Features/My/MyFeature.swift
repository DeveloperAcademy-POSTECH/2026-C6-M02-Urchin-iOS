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
        var profile: Profile?
        var savedProfileImage: Data?
        @Presents var profileEdit: ProfileEditFeature.State?
        @Presents var settings: SettingsFeature.State?
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case profileResponse(Result<Profile?, any Error>)
        case profileEditButtonTapped
        case profileEdit(PresentationAction<ProfileEditFeature.Action>)
        case settingsButtonTapped
        case settings(PresentationAction<SettingsFeature.Action>)
        case delegate(Delegate)

        enum Delegate {
            case signedOut
        }
    }

    // MARK: - Dependency

    @Dependency(\.userClient) var userClient

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard case .member = state.membershipStatus else { return .none }

                return fetchMyProfile()

            case let .profileResponse(.success(profile)):
                state.profile = profile
                return .none

            case let .profileResponse(.failure(error)):
                PlobbyLogger.error(error)
                return .none

            case .profileEditButtonTapped:
                guard let profile = state.profile else { return .none }

                state.profileEdit = ProfileEditFeature.State(profile: profile)
                return .none

            case let .profileEdit(.presented(.delegate(.saved(profile, profileImage)))):
                state.profile = profile

                if let profileImage {
                    state.savedProfileImage = profileImage
                }
                return .none

            case .profileEdit:
                return .none

            case .settingsButtonTapped:
                state.settings = SettingsFeature.State()
                return .none

            case .settings(.presented(.delegate(.signedOut))):
                state.settings = nil
                return .send(.delegate(.signedOut))

            case .settings, .delegate:
                return .none
            }
        }
        .ifLet(\.$profileEdit, action: \.profileEdit) {
            ProfileEditFeature()
        }
        .ifLet(\.$settings, action: \.settings) {
            SettingsFeature()
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
}
