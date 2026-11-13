//
//  PhotoLibraryClient.swift
//  Plobby
//
//  Created by 더스틴 on 11/4/26.
//

import AVFoundation
import Photos
import UIKit

import Dependencies

struct PhotoLibraryClient {
    
    var authorizationStatus: @Sendable () -> PhotoAuthorization
    var requestAuthorization: @Sendable () async -> PhotoAuthorization
    /// 카메라 권한을 확인해요. 아직 묻지 않았으면 iOS 권한 팝업을 띄워요.
    var requestCameraAuthorization: @Sendable () async -> Bool
    var fetchAlbums: @Sendable () async -> [PhotoAlbum]
    var fetchAssets: @Sendable (_ albumID: PhotoAlbum.ID) async -> [PhotoAsset]
    var thumbnail: @Sendable (_ assetID: PhotoAsset.ID, _ targetSize: CGSize) async -> UIImage?
    var imageData: @Sendable (_ assetID: PhotoAsset.ID) async throws -> Data
    var saveImage: @Sendable (_ imageData: Data) async throws -> PhotoAsset
    /// 사진 보관함이 바뀔 때마다 알려줘요. 일부 접근에서 사진을 더 고르면 목록을 다시 불러오려고 써요.
    var libraryChanges: @Sendable () -> AsyncStream<Void>
}

extension PhotoLibraryClient: DependencyKey {
    static let liveValue: PhotoLibraryClient = {
        .init(
            authorizationStatus: {
                PhotoAuthorization(PHPhotoLibrary.authorizationStatus(for: .readWrite))
            },
            requestAuthorization: {
                PhotoAuthorization(await PHPhotoLibrary.requestAuthorization(for: .readWrite))
            },
            requestCameraAuthorization: {
                switch AVCaptureDevice.authorizationStatus(for: .video) {
                case .authorized: true
                case .notDetermined: await AVCaptureDevice.requestAccess(for: .video)
                default: false
                }
            },
            fetchAlbums: {
                PhotoLibrary.albumCollections().compactMap { collection in
                    let assets = PHAsset.fetchAssets(in: collection, options: PhotoLibrary.imageFetchOptions())
                    guard assets.count > 0 else { return nil }

                    return PhotoAlbum(
                        id: collection.localIdentifier,
                        title: collection.localizedTitle ?? "",
                        assetCount: assets.count,
                        thumbnailAssetID: assets.firstObject?.localIdentifier
                    )
                }
            },
            fetchAssets: { albumID in
                guard let collection = PHAssetCollection.fetchAssetCollections(
                    withLocalIdentifiers: [albumID],
                    options: nil
                ).firstObject else {
                    return []
                }

                let assets = PHAsset.fetchAssets(in: collection, options: PhotoLibrary.imageFetchOptions())
                return (0..<assets.count).map { PhotoAsset(id: assets.object(at: $0).localIdentifier) }
            },
            thumbnail: { assetID, targetSize in
                guard let asset = PhotoLibrary.asset(for: assetID) else { return nil }

                let options = PHImageRequestOptions()
                options.deliveryMode = .highQualityFormat
                options.resizeMode = .fast
                options.isNetworkAccessAllowed = true

                return await withCheckedContinuation { continuation in
                    PHImageManager.default().requestImage(
                        for: asset,
                        targetSize: targetSize,
                        contentMode: .aspectFill,
                        options: options
                    ) { image, _ in
                        continuation.resume(returning: image)
                    }
                }
            },
            imageData: { assetID in
                guard let asset = PhotoLibrary.asset(for: assetID) else {
                    throw PhotoLibraryError.assetNotFound
                }

                let options = PHImageRequestOptions()
                options.deliveryMode = .highQualityFormat
                options.isNetworkAccessAllowed = true

                return try await withCheckedThrowingContinuation { continuation in
                    PHImageManager.default().requestImageDataAndOrientation(
                        for: asset,
                        options: options
                    ) { data, _, _, info in
                        if let data {
                            continuation.resume(returning: data)
                        } else {
                            let error = info?[PHImageErrorKey] as? Error ?? PhotoLibraryError.imageUnavailable
                            continuation.resume(throwing: error)
                        }
                    }
                }
            },
            saveImage: { imageData in
                let placeholder = LockIsolated<String?>(nil)

                try await PHPhotoLibrary.shared().performChanges {
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResource(with: .photo, data: imageData, options: nil)
                    placeholder.setValue(request.placeholderForCreatedAsset?.localIdentifier)
                }

                guard let assetID = placeholder.value else {
                    throw PhotoLibraryError.saveFailed
                }
                return PhotoAsset(id: assetID)
            },
            libraryChanges: {
                AsyncStream { continuation in
                    let observer = PhotoLibraryChangeObserver { continuation.yield() }
                    PHPhotoLibrary.shared().register(observer)
                    continuation.onTermination = { _ in
                        PHPhotoLibrary.shared().unregisterChangeObserver(observer)
                    }
                }
            }
        )
    }()

    static let testValue = PhotoLibraryClient(
        authorizationStatus: unimplemented("PhotoLibraryClient.authorizationStatus", placeholder: .notDetermined),
        requestAuthorization: unimplemented("PhotoLibraryClient.requestAuthorization", placeholder: .notDetermined),
        requestCameraAuthorization: unimplemented("PhotoLibraryClient.requestCameraAuthorization", placeholder: false),
        fetchAlbums: unimplemented("PhotoLibraryClient.fetchAlbums", placeholder: []),
        fetchAssets: unimplemented("PhotoLibraryClient.fetchAssets", placeholder: []),
        thumbnail: unimplemented("PhotoLibraryClient.thumbnail", placeholder: nil),
        imageData: unimplemented("PhotoLibraryClient.imageData"),
        saveImage: unimplemented("PhotoLibraryClient.saveImage"),
        libraryChanges: unimplemented("PhotoLibraryClient.libraryChanges", placeholder: .finished)
    )
}

// MARK: - Error

nonisolated enum PhotoLibraryError: Error, Equatable {
    case assetNotFound
    case imageUnavailable
    case saveFailed
}

// MARK: - PhotoKit

nonisolated private enum PhotoLibrary {

    /// 최근 항목, 즐겨찾기, 셀피 등 사진이 있는 기본 폴더를 먼저, 사용자가 만든 앨범을 뒤에 둬요.
    static func albumCollections() -> [PHAssetCollection] {
        let smartAlbumTypes: [PHAssetCollectionSubtype] = [
            .smartAlbumUserLibrary,
            .smartAlbumFavorites,
            .smartAlbumSelfPortraits,
            .smartAlbumScreenshots,
            .smartAlbumLivePhotos,
            .smartAlbumPanoramas
        ]
        let smartAlbums = smartAlbumTypes.compactMap { subtype in
            PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: subtype, options: nil).firstObject
        }

        let userAlbumResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        let userAlbums = (0..<userAlbumResult.count).map { userAlbumResult.object(at: $0) }

        return smartAlbums + userAlbums
    }

    /// 사진만, 최신순으로 가져와요.
    static func imageFetchOptions() -> PHFetchOptions {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return options
    }

    static func asset(for id: PhotoAsset.ID) -> PHAsset? {
        PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject
    }
}

// MARK: - Change Observer

nonisolated private final class PhotoLibraryChangeObserver: NSObject, PHPhotoLibraryChangeObserver, Sendable {

    private let onChange: @Sendable () -> Void

    init(onChange: @escaping @Sendable () -> Void) {
        self.onChange = onChange
    }

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        onChange()
    }
}

// MARK: - PhotoAuthorization

nonisolated private extension PhotoAuthorization {

    init(_ status: PHAuthorizationStatus) {
        switch status {
        case .notDetermined: self = .notDetermined
        case .authorized: self = .authorized
        case .limited: self = .limited
        case .denied, .restricted: self = .denied
        @unknown default: self = .denied
        }
    }
}
