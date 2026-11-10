//
//  ProfilePhotoFeature.swift
//  Plobby
//
//  Created by dlsundn on 11/10/26.
//

import Foundation
import UIKit

import ComposableArchitecture

/// 회원가입과 프로필 수정에서 함께 쓰는 프로필 사진 고르기예요.
/// 앱 사진 선택 화면에서 한 장을 고르면 2MB 아래로 줄여 `selectedImage`에 담아요.
@Reducer
struct ProfilePhotoFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        /// 이미 저장된 사진이에요. 새로 고른 사진이 없을 때 보여줘요.
        let savedImageURL: URL?
        var selectedImage: Data?
        var isLoading = false
        @Presents var photoPicker: PhotosPickerFeature.State?
        @Presents var alert: AlertState<Action.Alert>?

        init(savedImageURL: URL? = nil) {
            self.savedImageURL = savedImageURL
        }
    }

    // MARK: - Action

    enum Action {
        case photoTapped
        case photoPicker(PresentationAction<PhotosPickerFeature.Action>)
        case imageLoadFailed
        case imageCompressed(Data?)
        case alert(PresentationAction<Alert>)

        enum Alert {
            case confirm
        }
    }

    // MARK: - Dependency

    @Dependency(\.photoLibraryClient) var photoLibraryClient

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .photoTapped:
                state.photoPicker = .profile
                return .none

            case let .photoPicker(.presented(.delegate(.finished(assets)))):
                state.photoPicker = nil
                guard let asset = assets.first else { return .none }

                state.isLoading = true
                return loadImage(asset.id)

            case .photoPicker(.presented(.delegate(.cancelled))):
                state.photoPicker = nil
                return .none

            case .imageLoadFailed:
                state.isLoading = false
                state.alert = .make(.profileImageLoadFailed)
                return .none

            case let .imageCompressed(data):
                state.isLoading = false
                guard let data else {
                    state.alert = .make(.profileImageTooLarge)
                    return .none
                }

                state.selectedImage = data
                return .none

            case .photoPicker, .alert:
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

extension ProfilePhotoFeature {

    /// 진행 중인 사진 불러오기를 가리키는 이름표예요.
    /// 다른 사진을 다시 고르면 이전 불러오기를 취소해서, 마지막에 고른 사진만 반영돼요.
    private nonisolated enum CancelID {
        case image
    }

    /// 원본을 못 받으면 큰 썸네일로 대신하고, 2MB 아래로 줄인 JPEG를 넘겨요. 줄이지 못하면 nil이에요.
    private func loadImage(_ assetID: PhotoAsset.ID) -> Effect<Action> {
        .run { send in
            var data = try? await photoLibraryClient.imageData(assetID)

            if data == nil {
                let fallbackSize = CGSize(width: 1024, height: 1024)
                data = await photoLibraryClient.thumbnail(assetID, fallbackSize)?.jpegData(compressionQuality: 0.9)
            }

            guard let data else {
                await send(.imageLoadFailed)
                return
            }

            let compressedData = await Task.detached(priority: .userInitiated) {
                ProfileImageCompressor.compressedJPEG(from: data)
            }.value

            await send(.imageCompressed(compressedData))
        }
        .cancellable(id: CancelID.image, cancelInFlight: true)
    }
}
