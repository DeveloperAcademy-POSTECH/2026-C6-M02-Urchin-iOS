//
//  PhotosPickerFeature.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import UIKit

import ComposableArchitecture

@Reducer
struct PhotosPickerFeature {
    
    // MARK: - State
    
    enum Purpose: Equatable {
        case record(RecordType)
        case profile
    }

    @ObservableState
    struct State: Equatable {
        let purpose: Purpose
        var authorization: PhotoAuthorization = .notDetermined
        var albums: [PhotoAlbum] = []
        var selectedAlbumID: PhotoAlbum.ID?
        var isAlbumListExpanded = false
        var assets: IdentifiedArrayOf<PhotoAsset> = []
        var selection: PhotoSelection
        var isCameraPresented = false
        var toast = ToastFeature.State()
        
        init(recordType: RecordType, alreadySelectedCount: Int = 0) {
            self.purpose = .record(recordType)
            self.selection = PhotoSelection(limit: PhotoSelection.maxCount - alreadySelectedCount)
        }

        static var profile: Self {
            Self(purpose: .profile, selection: PhotoSelection(limit: 1))
        }

        private init(purpose: Purpose, selection: PhotoSelection) {
            self.purpose = purpose
            self.selection = selection
        }

        var isSingleSelection: Bool {
            purpose == .profile
        }
        
        var selectedAlbum: PhotoAlbum? {
            albums.first { $0.id == selectedAlbumID }
        }
        
        var isSkip: Bool {
            selection.isEmpty
        }
    }
    
    // MARK: - Action
    
    enum Action {
        case task
        case authorizationResponse(PhotoAuthorization)
        case albumsResponse([PhotoAlbum])
        case assetsResponse([PhotoAsset])
        case albumToggleTapped
        case albumSelected(PhotoAlbum.ID)
        case assetTapped(PhotoAsset.ID)
        case cameraTapped
        case cameraDismissed
        case cameraImageCaptured(Data)
        case cameraCaptured(PhotoAsset)
        case cameraSaveFailed
        case openSettingsTapped
        case bottomButtonTapped
        case closeTapped
        case toast(ToastFeature.Action)
        case delegate(Delegate)
        
        @CasePathable
        enum Delegate {
            case finished([PhotoAsset])
            case cancelled
        }
    }
    
    // MARK: - Dependency
    
    @Dependency(\.photoLibraryClient) var photoLibraryClient
    @Dependency(\.openURL) var openURL
    
    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        Scope(state: \.toast, action: \.toast) {
            ToastFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .task:
                let status = photoLibraryClient.authorizationStatus()
                return handlePhotoAuthorization(currentStatus: status)
                
            case let .authorizationResponse(authorization):
                state.authorization = authorization
                guard authorization.canReadLibrary else {
                    return .none
                }
                
                return fetchAlbums()
                
            case let .albumsResponse(albums):
                state.albums = albums
                guard let album = albums.first else {
                    state.selectedAlbumID = nil
                    state.assets = []
                    return .none
                }
                
                state.selectedAlbumID = album.id
                return fetchAssets(in: album.id)
                
            case let .assetsResponse(assets):
                state.assets = IdentifiedArray(uniqueElements: assets)
                return .none
                
            case .albumToggleTapped:
                guard !state.albums.isEmpty else {
                    return .none
                }
                
                state.isAlbumListExpanded.toggle()
                return .none
                
            case let .albumSelected(albumID):
                state.selectedAlbumID = albumID
                state.isAlbumListExpanded = false
                return fetchAssets(in: albumID)
                
            case let .assetTapped(assetID):
                guard let asset = state.assets[id: assetID] else {
                    return .none
                }

                if state.isSingleSelection, !state.selection.contains(asset.id) {
                    state.selection = PhotoSelection([asset], limit: 1)
                    return .none
                }
                
                guard state.selection.toggle(asset) != .limitExceeded else {
                    return .send(.toast(.show(Self.limitExceededMessage)))
                }
                
                return .none
                
            case .cameraTapped:
                guard state.authorization.canReadLibrary else {
                    return .none
                }
                
                guard state.isSingleSelection || !state.selection.isFull else {
                    return .send(.toast(.show(Self.limitExceededMessage)))
                }
                
                state.isCameraPresented = true
                return .none
                
            case .cameraDismissed:
                state.isCameraPresented = false
                return .none
                
            case let .cameraImageCaptured(imageData):
                state.isCameraPresented = false
                return saveImageInGallery(source: imageData)
                
            case let .cameraCaptured(asset):
                if state.selectedAlbumID == state.albums.first?.id {
                    state.assets.insert(asset, at: 0)
                }
                if state.isSingleSelection {
                    state.selection = PhotoSelection([asset], limit: 1)
                } else {
                    state.selection.append(asset)
                }
                return .none
                
            case .cameraSaveFailed:
                return .send(.toast(.show(Self.cameraSaveFailedMessage)))
                
            case .openSettingsTapped:
                guard let url = URL(string: UIApplication.openSettingsURLString) else {
                    return .none
                }
                
                return .run { _ in
                    await openURL(url)
                }
                
            case .bottomButtonTapped:
                return .send(.delegate(.finished(state.selection.assets)))
                
            case .closeTapped:
                return .send(.delegate(.cancelled))
                
            case .toast, .delegate:
                return .none
            }
        }
    }
}

// MARK: - Constants

extension PhotosPickerFeature {
    
    static let limitExceededMessage = "사진은 최대 \(PhotoSelection.maxCount)장까지 선택할 수 있어요."
    static let cameraSaveFailedMessage = "사진을 저장하지 못했어요. 다시 시도해주세요."
}

// MARK: - Functions

private extension PhotosPickerFeature {
    
    nonisolated private enum CancelID {
        case fetchAssets
    }
    
    func handlePhotoAuthorization(currentStatus: PhotoAuthorization) -> Effect<Action> {
        return .run { send in
            let result = currentStatus == .notDetermined
            ? await photoLibraryClient.requestAuthorization()
            : currentStatus
            
            await send(.authorizationResponse(result))
        }
    }
    
    func fetchAlbums() -> Effect<Action> {
        return .run { send in
            let photoAlbums = await photoLibraryClient.fetchAlbums()
            await send(.albumsResponse(photoAlbums))
        }
    }
    
    func saveImageInGallery(source imageData: Data) -> Effect<Action> {
        return .run { send in
            do {
                let asset = try await photoLibraryClient.saveImage(imageData)
                await send(.cameraCaptured(asset))
            } catch {
                await send(.cameraSaveFailed)
            }
        }
    }
    
    func fetchAssets(in albumID: PhotoAlbum.ID) -> Effect<Action> {
        .run { send in
            let assets = await photoLibraryClient.fetchAssets(albumID)
            await send(.assetsResponse(assets))
        }
        .cancellable(id: CancelID.fetchAssets, cancelInFlight: true)
    }
}
