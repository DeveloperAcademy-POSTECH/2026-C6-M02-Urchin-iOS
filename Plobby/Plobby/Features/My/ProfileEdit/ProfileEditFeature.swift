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
        var nickname: String
        var selectedImage: Data?
        var isCheckingNickname = false
        var isNicknameAvailable: Bool?
        var isImageLoading = false
        var isImageTooLarge = false
        var isSaving = false
        @Presents var alert: AlertState<Action.Alert>?

        init(profile: Profile) {
            self.profile = profile
            self.nickname = profile.nickname
        }

        var isNicknameFormatInvalid: Bool {
            !nickname.isEmpty && !Nickname.isValid(nickname)
        }

        var isNicknameChanged: Bool {
            nickname != profile.nickname
        }

        var canCheckNickname: Bool {
            isNicknameChanged && Nickname.isValid(nickname) && !isCheckingNickname
        }

        var canSave: Bool {
            guard !isSaving, !isImageLoading else { return false }

            return isNicknameChanged
                ? isNicknameAvailable == true
                : selectedImage != nil
        }
    }

    // MARK: - Action

    enum Action {
        case backButtonTapped
        case profileImageLoadingStarted
        case profileImageSelected(Data?)
        case profileImageCompressed(Data?)
        case nicknameChanged(String)
        case nicknameCheckButtonTapped
        case nicknameCheckResponse(Result<Bool, any Error>)
        case saveButtonTapped
        case saveResponse(Result<Profile, any Error>)
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
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                return .run { _ in
                    await dismiss()
                }

            case .profileImageLoadingStarted:
                state.isImageLoading = true
                state.isImageTooLarge = false
                return .none

            case let .profileImageSelected(data):
                guard let data else {
                    state.isImageLoading = false
                    return .none
                }

                return compressProfileImage(data)

            case let .profileImageCompressed(data):
                state.isImageLoading = false

                guard let data else {
                    state.isImageTooLarge = true
                    state.selectedImage = nil
                    return .none
                }

                state.selectedImage = data
                return .none

            case let .nicknameChanged(nickname):
                let nickname = String(nickname.prefix(Nickname.maximumLength))
                guard nickname != state.nickname else { return .none }

                state.nickname = nickname
                state.isCheckingNickname = false
                state.isNicknameAvailable = nil
                return .cancel(id: CancelID.nicknameCheck)

            case .nicknameCheckButtonTapped:
                guard state.canCheckNickname else { return .none }

                state.isCheckingNickname = true
                return checkNickname(state.nickname)

            case let .nicknameCheckResponse(.success(isAvailable)):
                state.isCheckingNickname = false
                state.isNicknameAvailable = isAvailable
                return .none

            case let .nicknameCheckResponse(.failure(error)):
                PlobbyLogger.error(error)
                state.isCheckingNickname = false
                return .none

            case .saveButtonTapped:
                guard state.canSave else { return .none }

                state.isSaving = true
                return saveProfile(nickname: state.nickname, profileImage: state.selectedImage)

            case let .saveResponse(.success(profile)):
                state.isSaving = false
                return .run { [profileImage = state.selectedImage] send in
                    await send(.delegate(.saved(profile, profileImage: profileImage)))
                    await dismiss()
                }

            case let .saveResponse(.failure(error)):
                PlobbyLogger.error(error)
                state.isSaving = false
                state.alert = .make(.profileUpdateFailed)
                return .none

            case .alert, .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

// MARK: - Functions

extension ProfileEditFeature {

    private nonisolated enum CancelID {
        case nicknameCheck
    }

    private func compressProfileImage(_ data: Data) -> Effect<Action> {
        .run { send in
            let compressedData = await Task.detached(priority: .userInitiated) {
                ProfileImageCompressor.compressedJPEG(from: data)
            }.value

            await send(.profileImageCompressed(compressedData))
        }
    }

    private func checkNickname(_ nickname: String) -> Effect<Action> {
        .run { send in
            await send(.nicknameCheckResponse(Result {
                try await userClient.fetchIsNicknameAvailable(nickname)
            }))
        }
        .cancellable(id: CancelID.nicknameCheck, cancelInFlight: true)
    }

    private func saveProfile(nickname: String, profileImage: Data?) -> Effect<Action> {
        .run { send in
            await send(.saveResponse(Result {
                try await userClient.updateMyProfile(nickname, profileImage)
            }))
        }
    }
}
