//
//  ProfileSetupFeature.swift
//  Plobby
//
//  Created by 이은지 on 11/9/26.
//

import Foundation
import UIKit

import ComposableArchitecture

@Reducer
struct ProfileSetupFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var profileImage: Data?
        var isLoadingProfileImage = false
        var nickname = ""
        var isCheckingNickname = false
        var isNicknameAvailable: Bool?
        @Presents var photoPicker: PhotosPickerFeature.State?
        @Presents var alert: AlertState<Action.Alert>?

        var isNicknameFormatInvalid: Bool {
            !nickname.isEmpty && !Nickname.isValid(nickname)
        }

        var hasNicknameError: Bool {
            isNicknameFormatInvalid || isNicknameAvailable == false
        }

        var canCheckNickname: Bool {
            Nickname.isValid(nickname) && !isCheckingNickname
        }

        var canGoNext: Bool {
            isNicknameAvailable == true && !isLoadingProfileImage
        }
    }

    // MARK: - Action

    enum Action {
        case profilePhotoTapped
        case photoPicker(PresentationAction<PhotosPickerFeature.Action>)
        case profileImageLoadFailed
        case profileImageCompressed(Data?)
        case nicknameChanged(String)
        case nicknameCheckButtonTapped
        case nicknameCheckResponse(Result<Bool, any Error>)
        case nextButtonTapped
        case alert(PresentationAction<Alert>)

        enum Alert {
            case confirm
        }
    }

    // MARK: - Dependency

    @Dependency(\.userClient) var userClient
    @Dependency(\.photoLibraryClient) var photoLibraryClient

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .profilePhotoTapped:
                state.photoPicker = .profile
                return .none

            case let .photoPicker(.presented(.delegate(.finished(assets)))):
                state.photoPicker = nil
                guard let asset = assets.first else { return .none }

                state.isLoadingProfileImage = true
                return loadProfileImage(asset.id)

            case .photoPicker(.presented(.delegate(.cancelled))):
                state.photoPicker = nil
                return .none

            case .photoPicker:
                return .none

            case .profileImageLoadFailed:
                state.isLoadingProfileImage = false
                state.alert = .make(.profileImageLoadFailed)
                return .none

            case let .profileImageCompressed(data):
                state.isLoadingProfileImage = false
                guard let data else {
                    state.alert = .make(.profileImageTooLarge)
                    return .none
                }

                state.profileImage = data
                return .none

            case let .nicknameChanged(nickname):
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

            case .nicknameCheckResponse(.failure):
                state.isCheckingNickname = false
                state.alert = .make(.nicknameCheckFailed)
                return .none

            case .nextButtonTapped, .alert:
                return .none
            }
        }
        .ifLet(\.$photoPicker, action: \.photoPicker) {
            PhotosPickerFeature()
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

// MARK: - Functions

private extension ProfileSetupFeature {

    nonisolated enum CancelID {
        case nicknameCheck
        case profileImage
    }

    func loadProfileImage(_ assetID: PhotoAsset.ID) -> Effect<Action> {
        .run { send in
            var data = try? await photoLibraryClient.imageData(assetID)

            if data == nil {
                let fallbackSize = CGSize(width: 1024, height: 1024)
                data = await photoLibraryClient.thumbnail(assetID, fallbackSize)?.jpegData(compressionQuality: 0.9)
            }

            guard let data else {
                await send(.profileImageLoadFailed)
                return
            }

            await send(.profileImageCompressed(ProfileImageCompressor.compressedJPEG(from: data)))
        }
        .cancellable(id: CancelID.profileImage, cancelInFlight: true)
    }

    func checkNickname(_ nickname: String) -> Effect<Action> {
        .run { send in
            await send(.nicknameCheckResponse(Result {
                try await userClient.fetchIsNicknameAvailable(nickname)
            }))
        }
        .cancellable(id: CancelID.nicknameCheck, cancelInFlight: true)
    }
}
