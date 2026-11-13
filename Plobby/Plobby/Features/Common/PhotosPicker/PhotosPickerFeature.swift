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
        /// 앨범 밖에서 이미 넣어 둔 사진 수예요. 수정 중인 기존 사진이 해당해요.
        let alreadySelectedCount: Int
        var isCameraPresented = false
        var toast = ToastFeature.State()
        @Presents var alert: AlertState<Action.Alert>?
        
        /// 기록 양식에 이미 넣은 사진은 선택된 채로 열어요.
        /// 앨범에서 다시 고를 수 없는 사진(수정 중인 기존 사진)은 그 장수만큼 한도에서 빼요.
        init(recordType: RecordType, selectedAssets: [PhotoAsset] = [], alreadySelectedCount: Int = 0) {
            self.purpose = .record(recordType)
            self.selection = PhotoSelection(selectedAssets, limit: PhotoSelection.maxCount - alreadySelectedCount)
            self.alreadySelectedCount = alreadySelectedCount
        }

        static var profile: Self {
            Self(purpose: .profile, selection: PhotoSelection(limit: 1))
        }

        private init(purpose: Purpose, selection: PhotoSelection) {
            self.purpose = purpose
            self.selection = selection
            self.alreadySelectedCount = 0
        }

        var isSingleSelection: Bool {
            purpose == .profile
        }
        
        var selectedAlbum: PhotoAlbum? {
            albums.first { $0.id == selectedAlbumID }
        }
        
        /// 기존 사진이 남아 있으면 앨범에서 모두 해제해도 확정할 수 있어요.
        var isSkip: Bool {
            selection.isEmpty && alreadySelectedCount == 0
        }
    }
    
    // MARK: - Action
    
    enum Action {
        case task
        /// 설정 앱에서 권한을 바꾸고 돌아오면 권한을 다시 확인해요.
        case sceneBecameActive
        case authorizationResponse(PhotoAuthorization)
        case albumsResponse([PhotoAlbum])
        /// 사진 보관함이 바뀌면 앨범과 사진을 다시 불러와요.
        case libraryChanged
        case assetsResponse([PhotoAsset])
        case albumToggleTapped
        case albumSelected(PhotoAlbum.ID)
        case assetTapped(PhotoAsset.ID)
        case cameraTapped
        case cameraAuthorizationResponse(Bool)
        case cameraDismissed
        case cameraImageCaptured(Data)
        case cameraCaptured(PhotoAsset)
        case cameraSaveFailed
        case openSettingsTapped
        case bottomButtonTapped
        case closeTapped
        case toast(ToastFeature.Action)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        enum Alert {
            case openSettingsTapped
        }
        
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

            case .sceneBecameActive:
                let status = photoLibraryClient.authorizationStatus()

                guard state.authorization != .notDetermined, status != state.authorization else { return .none }

                return .send(.authorizationResponse(status))
                
            case let .authorizationResponse(authorization):
                state.authorization = authorization
                guard authorization.canReadLibrary else {
                    return .none
                }
                
                return .merge(fetchAlbums(), observeLibraryChanges())

            case .libraryChanged:
                return fetchAlbums()
                
            case let .albumsResponse(albums):
                state.albums = albums
                let selectedAlbum = albums.first { $0.id == state.selectedAlbumID } ?? albums.first

                guard let album = selectedAlbum else {
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
                    return .send(.toast(.show(.photoLimitExceeded)))
                }
                
                return .none
                
            case .cameraTapped:
                guard state.authorization.canReadLibrary else {
                    return .none
                }
                
                guard state.isSingleSelection || !state.selection.isFull else {
                    return .send(.toast(.show(.photoLimitExceeded)))
                }
                
                return .run { send in
                    await send(.cameraAuthorizationResponse(await photoLibraryClient.requestCameraAuthorization()))
                }

            case let .cameraAuthorizationResponse(isAuthorized):
                guard isAuthorized else {
                    state.alert = .make(.cameraAccessDenied, confirm: .openSettingsTapped)
                    return .none
                }

                state.isCameraPresented = true
                return .none

            case .alert(.presented(.openSettingsTapped)):
                return .send(.openSettingsTapped)
                
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
                return .send(.toast(.show(.photoSaveFailed)))
                
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
                
            case .toast, .alert, .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}


// MARK: - Functions

private extension PhotosPickerFeature {
    
    nonisolated private enum CancelID {
        case fetchAssets
        case libraryChanges
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
    
    func observeLibraryChanges() -> Effect<Action> {
        .run { send in
            for await _ in photoLibraryClient.libraryChanges() {
                await send(.libraryChanged)
            }
        }
        .cancellable(id: CancelID.libraryChanges, cancelInFlight: true)
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
