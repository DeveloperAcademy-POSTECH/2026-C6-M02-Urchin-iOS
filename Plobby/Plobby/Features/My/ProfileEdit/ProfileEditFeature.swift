//
//  ProfileEditFeature.swift
//  Plobby
//
//  Created by dlsundn on 11/5/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct ProfileEditFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        let profile: Profile
        var profilePhoto: ProfilePhotoFeature.State
        var nicknameCheck: NicknameCheckFeature.State
        var isSaving = false
        @Presents var alert: AlertState<Action.Alert>?

        init(profile: Profile) {
            self.profile = profile
            self.profilePhoto = ProfilePhotoFeature.State(savedImageURL: profile.profileImageURL)
            self.nicknameCheck = NicknameCheckFeature.State(originalNickname: profile.nickname)
        }

        /// 닉네임을 바꿨다면 중복 확인을 마쳐야 하고, 그대로라면 새 사진을 골라야 저장할 수 있어요.
        var canSave: Bool {
            guard !isSaving, !profilePhoto.isLoading else { return false }

            return nicknameCheck.isChanged
                ? nicknameCheck.isChecked
                : profilePhoto.selectedImage != nil
        }
    }

    // MARK: - Action

    enum Action {
        case backButtonTapped
        case saveButtonTapped
        case saveResponse(Result<Profile, any Error>)
        case profilePhoto(ProfilePhotoFeature.Action)
        case nicknameCheck(NicknameCheckFeature.Action)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        enum Alert {
            case confirm
        }

        enum Delegate {
            case saved(Profile, profileImage: Data?)
        }
    }

    // MARK: - Dependency

    @Dependency(\.dismiss) var dismiss
    @Dependency(\.userClient) var userClient

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Scope(state: \.profilePhoto, action: \.profilePhoto) {
            ProfilePhotoFeature()
        }

        Scope(state: \.nicknameCheck, action: \.nicknameCheck) {
            NicknameCheckFeature()
        }

        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                return .run { _ in
                    await dismiss()
                }

            case .saveButtonTapped:
                guard state.canSave else { return .none }

                state.isSaving = true
                return saveProfile(
                    nickname: state.nicknameCheck.nickname,
                    profileImage: state.profilePhoto.selectedImage
                )

            case let .saveResponse(.success(profile)):
                state.isSaving = false
                return .run { [profileImage = state.profilePhoto.selectedImage] send in
                    await send(.delegate(.saved(profile, profileImage: profileImage)))
                    await dismiss()
                }

            case let .saveResponse(.failure(error)):
                PlobbyLogger.error(error)
                state.isSaving = false
                state.alert = .make(.profileUpdateFailed)
                return .none

            case .profilePhoto, .nicknameCheck, .alert, .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

// MARK: - Functions

extension ProfileEditFeature {

    private func saveProfile(nickname: String, profileImage: Data?) -> Effect<Action> {
        .run { send in
            await send(.saveResponse(Result {
                try await userClient.updateMyProfile(nickname, profileImage)
            }))
        }
    }
}
