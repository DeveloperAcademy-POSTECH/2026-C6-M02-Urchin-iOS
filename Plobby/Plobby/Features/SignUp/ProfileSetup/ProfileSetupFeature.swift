//
//  ProfileSetupFeature.swift
//  Plobby
//
//  Created by 이은지 on 11/9/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct ProfileSetupFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var profilePhoto = ProfilePhotoFeature.State()
        var nicknameCheck = NicknameCheckFeature.State()

        var profileImage: Data? {
            profilePhoto.selectedImage
        }

        var nickname: String {
            nicknameCheck.nickname
        }

        var canGoNext: Bool {
            nicknameCheck.isChecked && !profilePhoto.isLoading
        }
    }

    // MARK: - Action

    enum Action {
        case profilePhoto(ProfilePhotoFeature.Action)
        case nicknameCheck(NicknameCheckFeature.Action)
        case backButtonTapped
        case nextButtonTapped
    }

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Scope(state: \.profilePhoto, action: \.profilePhoto) {
            ProfilePhotoFeature()
        }

        Scope(state: \.nicknameCheck, action: \.nicknameCheck) {
            NicknameCheckFeature()
        }
    }
}
