//
//  SignUpFeature.swift
//  Plobby
//
//  Created by 이은지 on 10/31/26.
//

import Foundation
import UIKit

import ComposableArchitecture

@Reducer
struct SignUpFeature {
    
    // MARK: - Path
    
    @Reducer
    enum Path {
        case profile(ProfileStepFeature)
        case region(RegionFeature)
        case complete(CompleteFeature)
    }

    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        let user: AuthUser
        var profileImage: Data?
        var nickname = ""
        var isCheckingNickname = false
        var isNicknameAvailable: Bool?
        var isSigningUp = false
        var isAgeConfirmed = false
        var isTermsAgreed = false
        var isPrivacyAgreed = false
        var path = StackState<Path.State>()
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
        
        var isAllAgreed: Bool {
            isAgeConfirmed && isTermsAgreed && isPrivacyAgreed
        }

        var canGoNext: Bool {
            isNicknameAvailable == true && !isSigningUp
        }
    }

    // MARK: - Action
    
    enum Action {
        case allAgreementTapped
        case ageConfirmationTapped
        case termsAgreementTapped
        case privacyAgreementTapped
        case agreementNextButtonTapped
        case profilePhotoTapped
        case photoPicker(PresentationAction<PhotosPickerFeature.Action>)
        case profileImageSelected(Data)
        case profileImageLoadFailed
        case profileImageCompressed(Data?)
        case alert(PresentationAction<Alert>)
        case nicknameChanged(String)
        case nicknameCheckButtonTapped
        case nicknameCheckResponse(Result<Bool, any Error>)
        case nextButtonTapped
        case signUpResponse(Result<Void, any Error>)
        case path(StackActionOf<Path>)
        case delegate(Delegate)
        
        enum Alert {
            case confirm
        }
        
        enum Delegate {
            case completed(AuthUser)
        }
    }
    
    // MARK: - Dependency
    
    @Dependency(\.authClient) var authClient
    @Dependency(\.userClient) var userClient
    @Dependency(\.photoLibraryClient) var photoLibraryClient

    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .allAgreementTapped:
                let isAgreed = !state.isAllAgreed
                state.isAgeConfirmed = isAgreed
                state.isTermsAgreed = isAgreed
                state.isPrivacyAgreed = isAgreed
                return .none

            case .ageConfirmationTapped:
                state.isAgeConfirmed.toggle()
                return .none

            case .termsAgreementTapped:
                state.isTermsAgreed.toggle()
                return .none

            case .privacyAgreementTapped:
                state.isPrivacyAgreed.toggle()
                return .none

            case .agreementNextButtonTapped:
                guard state.isAllAgreed else { return .none }

                state.path.append(.profile(ProfileStepFeature.State()))
                return .none

            case .profilePhotoTapped:
                state.photoPicker = .profile
                return .none

            case let .photoPicker(.presented(.delegate(.finished(assets)))):
                state.photoPicker = nil
                guard let asset = assets.first else { return .none }

                return fetchProfileImageData(asset.id)

            case .photoPicker(.presented(.delegate(.cancelled))):
                state.photoPicker = nil
                return .none

            case .photoPicker:
                return .none

            case let .profileImageSelected(data):
                return compressProfileImage(data)

            case .profileImageLoadFailed:
                state.alert = .make(.profileImageLoadFailed)
                return .none
                
            case let .profileImageCompressed(data):
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
                return .none
                
            case .nextButtonTapped:
                guard state.canGoNext else { return .none }

                state.path.append(.region(RegionFeature.State()))
                return .none

            case let .path(.element(id: id, action: .region(.nextButtonTapped))):
                guard !state.isSigningUp else { return .none }

                state.isSigningUp = true
                
                return signUp(SignUpProfile(
                    userID: state.user.id,
                    profileImage: state.profileImage,
                    nickname: state.nickname,
                    favoriteBeachIDs: Array(state.path[id: id]?.region?.picker.selectedBeachIDs ?? [])
                ))
                
            case .signUpResponse(.success):
                state.isSigningUp = false
                state.path.append(.complete(CompleteFeature.State()))
                return .none
                
            case .signUpResponse(.failure):
                state.isSigningUp = false
                state.alert = .make(.signUpFailed)
                return .none

            case .path(.element(id: _, action: .complete(.completeButtonTapped))):
                return .send(.delegate(.completed(state.user)))

            case .path, .alert, .delegate:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
        .ifLet(\.$photoPicker, action: \.photoPicker) {
            PhotosPickerFeature()
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

// MARK: - Functions

extension SignUpFeature {
    
    private nonisolated enum CancelID {
        case nicknameCheck
    }
    
    private func fetchProfileImageData(_ assetID: PhotoAsset.ID) -> Effect<Action> {
        .run { send in
            if let data = try? await photoLibraryClient.imageData(assetID) {
                await send(.profileImageSelected(data))
                return
            }

            let fallbackSize = CGSize(width: 1024, height: 1024)
            guard
                let image = await photoLibraryClient.thumbnail(assetID, fallbackSize),
                let data = image.jpegData(compressionQuality: 0.9)
            else {
                await send(.profileImageLoadFailed)
                return
            }

            await send(.profileImageSelected(data))
        }
    }

    private func compressProfileImage(_ data: Data) -> Effect<Action> {
        .run { send in
            await send(.profileImageCompressed(
                ProfileImageCompressor.compressedJPEG(from: data)
            ))
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
    
    private func signUp(_ profile: SignUpProfile) -> Effect<Action> {
        .run { send in
            await send(.signUpResponse(Result {
                try await authClient.signUp(profile)
            }))
        }
    }
}

// MARK: - ProfileStepFeature

@Reducer
struct ProfileStepFeature {

    @ObservableState
    struct State: Equatable {}

    enum Action {}

    var body: some Reducer<State, Action> {
        EmptyReducer()
    }
}

// MARK: - Conformance

extension SignUpFeature.Path.State: Equatable {}
