//
//  PhotosPickerFeatureTests.swift
//  PlobbyTests
//
//  Created by 더스틴 on 11/4/26.
//

import Foundation
import Testing

import ComposableArchitecture
@testable import Plobby

@MainActor
struct PhotosPickerFeatureTests {

    private let recents = PhotoAlbum(id: "recents", title: "최근 항목", assetCount: 3, thumbnailAssetID: "a")
    private let favorites = PhotoAlbum(id: "favorites", title: "즐겨찾기", assetCount: 1, thumbnailAssetID: "c")
    private let photos = ["a", "b", "c", "d", "e", "f"].map { PhotoAsset(id: $0) }

    // MARK: - 권한과 로드

    @Test
    func 권한을_허용하면_첫_폴더의_사진을_불러온다() async {
        let store = makeStore { client in
            client.authorizationStatus = { .notDetermined }
            client.requestAuthorization = { .authorized }
            client.fetchAlbums = { [recents, favorites] }
            client.fetchAssets = { _ in Array(photos.prefix(3)) }
        }

        await store.send(.task)
        await store.receive(\.authorizationResponse) {
            $0.authorization = .authorized
        }
        await store.receive(\.albumsResponse) {
            $0.albums = [self.recents, self.favorites]
            $0.selectedAlbumID = self.recents.id
        }
        await store.receive(\.assetsResponse) {
            $0.assets = IdentifiedArray(uniqueElements: self.photos.prefix(3))
        }
    }

    @Test
    func 권한이_거부되어_있으면_사진을_불러오지_않는다() async {
        let store = makeStore { client in
            client.authorizationStatus = { .denied }
        }

        await store.send(.task)
        await store.receive(\.authorizationResponse) {
            $0.authorization = .denied
        }
    }

    @Test
    func 폴더를_고르면_목록을_접고_그_폴더의_사진을_불러온다() async {
        var state = loadedState()
        state.isAlbumListExpanded = true
        let store = makeStore(state: state) { client in
            client.fetchAssets = { _ in [photos[2]] }
        }

        await store.send(.albumSelected(favorites.id)) {
            $0.selectedAlbumID = self.favorites.id
            $0.isAlbumListExpanded = false
        }
        await store.receive(\.assetsResponse) {
            $0.assets = [self.photos[2]]
        }
    }

    // MARK: - 선택

    @Test
    func 사진을_누르면_순서대로_선택되고_다시_누르면_해제된다() async {
        let store = makeStore(state: loadedState())

        await store.send(.assetTapped("a")) {
            $0.selection = PhotoSelection([self.photos[0]])
        }
        await store.send(.assetTapped("b")) {
            $0.selection = PhotoSelection([self.photos[0], self.photos[1]])
        }
        await store.send(.assetTapped("a")) {
            $0.selection = PhotoSelection([self.photos[1]])
        }

        #expect(store.state.selection.order(of: "b") == 1)
        #expect(store.state.isSkip == false)
    }

    @Test
    func 다섯_장을_넘기면_토스트를_띄우고_잠시_뒤_닫는다() async {
        let clock = TestClock()
        var state = loadedState()
        state.selection = PhotoSelection(Array(photos.prefix(5)))
        let store = makeStore(state: state, clock: clock)

        await store.send(.assetTapped("f"))
        await store.receive(\.toast.show) {
            $0.toast.toastType = .photoLimitExceeded
        }
        await clock.advance(by: ToastFeature.toastDuration)
        await store.receive(\.toast.toastDismissed) {
            $0.toast.toastType = nil
        }
    }

    @Test
    func 기록_양식에_사진이_있으면_남은_장수만큼만_고를_수_있다() async {
        let clock = TestClock()
        var state = PhotosPickerFeature.State(recordType: .plobbing, alreadySelectedCount: 3)
        state.assets = IdentifiedArray(uniqueElements: photos)
        let store = makeStore(state: state, clock: clock)

        await store.send(.assetTapped("a")) {
            $0.selection = PhotoSelection([self.photos[0]], limit: 2)
        }
        await store.send(.assetTapped("b")) {
            $0.selection = PhotoSelection([self.photos[0], self.photos[1]], limit: 2)
        }
        await store.send(.assetTapped("c"))
        await store.receive(\.toast.show) {
            $0.toast.toastType = .photoLimitExceeded
        }
        await clock.advance(by: ToastFeature.toastDuration)
        await store.receive(\.toast.toastDismissed) {
            $0.toast.toastType = nil
        }
    }

    // MARK: - 카메라

    @Test
    func 촬영한_사진은_저장한_뒤_맨_앞에_넣고_선택한다() async {
        let captured = PhotoAsset(id: "captured")
        let store = makeStore(state: loadedState()) { client in
            client.saveImage = { _ in captured }
        }

        await store.send(.cameraTapped) {
            $0.isCameraPresented = true
        }
        await store.send(.cameraImageCaptured(Data())) {
            $0.isCameraPresented = false
        }
        await store.receive(\.cameraCaptured) {
            $0.assets.insert(captured, at: 0)
            $0.selection = PhotoSelection([captured])
        }
    }

    // MARK: - 완료와 닫기

    @Test
    func 다음을_누르면_고른_사진을_선택_순서대로_전달한다() async {
        var state = loadedState()
        state.selection = PhotoSelection([photos[1], photos[0]])
        let store = makeStore(state: state)

        await store.send(.bottomButtonTapped)
        await store.receive(\.delegate.finished, [photos[1], photos[0]])
    }

    @Test
    func 닫기를_누르면_취소를_알린다() async {
        let store = makeStore(state: loadedState())

        await store.send(.closeTapped)
        await store.receive(\.delegate.cancelled)
    }

    // MARK: - Helpers

    /// 권한을 받고 최근 항목의 사진까지 불러온 상태예요.
    private func loadedState() -> PhotosPickerFeature.State {
        var state = PhotosPickerFeature.State(recordType: .plobbing)
        state.authorization = .authorized
        state.albums = [recents, favorites]
        state.selectedAlbumID = recents.id
        state.assets = IdentifiedArray(uniqueElements: photos)
        return state
    }

    private func makeStore(
        state: PhotosPickerFeature.State? = nil,
        clock: TestClock<Duration> = TestClock(),
        configure: (inout PhotoLibraryClient) -> Void = { _ in }
    ) -> TestStoreOf<PhotosPickerFeature> {
        TestStore(initialState: state ?? PhotosPickerFeature.State(recordType: .plobbing)) {
            PhotosPickerFeature()
        } withDependencies: {
            var client = PhotoLibraryClient.testValue
            configure(&client)
            $0.photoLibraryClient = client
            $0.continuousClock = clock
        }
    }
}
