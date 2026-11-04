//
//  PhotosPickerView.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import SwiftUI

import ComposableArchitecture

// TODO: 추후 디자인 시스템에 맞게 색상과 폰트를 수정
struct PhotosPickerView: View {

    // MARK: - Properties

    let store: StoreOf<PhotosPickerFeature>

    private let columnCount = 3
    private let gridSpacing: CGFloat = 1
    private let albumThumbnailLength: CGFloat = 48

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            navigationBar
            content
        }
        .background(Color.white)
        .task {
            await store.send(.task).finish()
        }
        .fullScreenCover(isPresented: cameraBinding) {
            cameraView
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.isAlbumListExpanded {
            albumList
        } else if store.authorization == .denied {
            deniedView
            bottomButton
        } else {
            guideBanner
            assetGrid
            bottomButton
        }
    }
}

// MARK: - Navigation Bar

private extension PhotosPickerView {

    var navigationBar: some View {
        ZStack {
            albumToggleButton
            closeButton
        }
        .padding(.horizontal, 20)
        .frame(height: 56)
    }

    var albumTitle: String {
        store.selectedAlbum?.title ?? "최근 항목"
    }

    var albumToggleButton: some View {
        Button {
            store.send(.albumToggleTapped)
        } label: {
            albumToggleLabel
        }
        .buttonStyle(.plain)
        .accessibilityLabel("앨범 선택, \(albumTitle)")
    }

    /// 화살표와 같은 너비의 빈 칸을 왼쪽에 둬서 제목이 화면 가운데에 오게 해요.
    var albumToggleLabel: some View {
        HStack(spacing: 8) {
            Color.clear
                .frame(width: 24, height: 24)

            Text(albumTitle)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.formPrimaryText)

            Image(systemName: store.isAlbumListExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.formPrimaryText)
                .frame(width: 24, height: 24)
        }
        .frame(height: 44)
        .contentShape(Rectangle())
    }

    var closeButton: some View {
        HStack {
            Button {
                store.send(.closeTapped)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.formPrimaryText)
                    .frame(width: 24, height: 24)
            }
            .accessibilityLabel("닫기")

            Spacer()
        }
    }
}

// MARK: - 안내 배너

private extension PhotosPickerView {

    var guideBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.square.on.square")
                .font(.system(size: 16))
                .foregroundStyle(Color.formPrimaryText)
                .frame(width: 20, height: 20)

            Text("\(store.recordType.name) 중 찍은 사진을 최대 \(PhotoSelection.maxCount)장까지 추가할 수 있어요")
                .font(.system(size: 13))
                .foregroundStyle(Color.formPrimaryText)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .frame(height: 56)
        .background(Color.photoPickerBanner)
    }
}

// MARK: - 사진 그리드

private extension PhotosPickerView {

    var assetGrid: some View {
        GeometryReader { proxy in
            let cellLength = cellLength(in: proxy.size.width)

            ScrollView {
                LazyVGrid(columns: gridColumns(cellLength: cellLength), spacing: gridSpacing) {
                    cameraCell(length: cellLength)
                    assetCells(length: cellLength)
                }
            }
        }
        .background(Color.white)
        .overlay(alignment: .bottom) {
            toast
        }
    }

    func cellLength(in width: CGFloat) -> CGFloat {
        (width - gridSpacing * CGFloat(columnCount - 1)) / CGFloat(columnCount)
    }

    func gridColumns(cellLength: CGFloat) -> [GridItem] {
        Array(
            repeating: GridItem(.fixed(cellLength), spacing: gridSpacing),
            count: columnCount
        )
    }

    func cameraCell(length: CGFloat) -> some View {
        Button {
            store.send(.cameraTapped)
        } label: {
            cameraCellLabel
                .frame(width: length, height: length)
                .background(Color.white)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("카메라로 촬영")
    }

    var cameraCellLabel: some View {
        VStack(spacing: 4) {
            Image(systemName: "camera.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color.formPrimaryText)
                .frame(width: 24, height: 24)

            Text("카메라")
                .font(.system(size: 12))
                .foregroundStyle(Color.formPrimaryText)
        }
    }

    func assetCells(length: CGFloat) -> some View {
        ForEach(store.assets) { asset in
            assetCell(asset, length: length)
        }
    }

    func assetCell(_ asset: PhotoAsset, length: CGFloat) -> some View {
        let order = store.selection.order(of: asset.id)

        return Button {
            store.send(.assetTapped(asset.id))
        } label: {
            PhotoThumbnailView(assetID: asset.id, size: CGSize(width: length, height: length))
                .overlay { selectedDim(isSelected: order != nil) }
                .overlay(alignment: .topTrailing) { selectionBadge(order: order) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(order.map { "선택된 사진, \($0)번째" } ?? "사진")
    }
}

// MARK: - 선택 표시

private extension PhotosPickerView {

    @ViewBuilder
    func selectedDim(isSelected: Bool) -> some View {
        if isSelected {
            Color.black.opacity(0.4)
        }
    }

    /// 선택 전에는 빈 원, 선택하면 순서 번호를 보여줘요.
    func selectionBadge(order: Int?) -> some View {
        Group {
            if let order {
                selectedBadge(order: order)
            } else {
                emptyBadge
            }
        }
        .frame(width: 24, height: 24)
        .shadow(color: .black.opacity(0.12), radius: 6, x: 4, y: 4)
        .padding(.top, 6)
        .padding(.trailing, 9)
    }

    func selectedBadge(order: Int) -> some View {
        Text("\(order)")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Color.formPrimaryText)
            .frame(width: 24, height: 24)
            .background(Color.white, in: Circle())
    }

    var emptyBadge: some View {
        Circle()
            .fill(Color.black.opacity(0.2))
            .overlay {
                Circle()
                    .strokeBorder(Color.white, lineWidth: 1)
            }
    }
}

// MARK: - 토스트

private extension PhotosPickerView {

    @ViewBuilder
    var toast: some View {
        if let message = store.toast.toastMessage {
            Text(message)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    Color.formPrimaryText.opacity(0.6),
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .transition(.opacity)
                .accessibilityAddTraits(.isStaticText)
        }
    }
}

// MARK: - 하단 버튼

private extension PhotosPickerView {

    var bottomButton: some View {
        Button {
            store.send(.bottomButtonTapped)
        } label: {
            bottomButtonLabel
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(Color.white)
    }

    var bottomButtonLabel: some View {
        Text(store.isSkip ? "건너뛰기" : "다음")
            .font(.system(size: store.isSkip ? 18 : 17, weight: .medium))
            .foregroundStyle(store.isSkip ? Color.formPrimaryText : .white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                store.isSkip ? Color.white : Color.formAccent,
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay { skipButtonBorder }
    }

    @ViewBuilder
    var skipButtonBorder: some View {
        if store.isSkip {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.formBorder, lineWidth: 1)
        }
    }
}

// MARK: - 앨범 목록

private extension PhotosPickerView {

    var albumList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(store.albums.enumerated()), id: \.element.id) { index, album in
                    albumListItem(album, showsDivider: index > 0)
                }
            }
        }
    }

    @ViewBuilder
    func albumListItem(_ album: PhotoAlbum, showsDivider: Bool) -> some View {
        if showsDivider {
            albumDivider
        }

        albumRow(album)
    }

    var albumDivider: some View {
        Rectangle()
            .fill(Color.formBorder)
            .frame(height: 1)
            .padding(.horizontal, 20)
    }

    func albumRow(_ album: PhotoAlbum) -> some View {
        Button {
            store.send(.albumSelected(album.id))
        } label: {
            HStack(spacing: 16) {
                albumThumbnail(album)
                albumTitleAndCount(album)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .frame(height: 80)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(album.title), 사진 \(album.assetCount)장")
    }

    func albumThumbnail(_ album: PhotoAlbum) -> some View {
        Group {
            if let thumbnailAssetID = album.thumbnailAssetID {
                PhotoThumbnailView(
                    assetID: thumbnailAssetID,
                    size: CGSize(width: albumThumbnailLength, height: albumThumbnailLength)
                )
            } else {
                Color.formFieldBackground
                    .frame(width: albumThumbnailLength, height: albumThumbnailLength)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    func albumTitleAndCount(_ album: PhotoAlbum) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(album.title)
                .font(.system(size: 17))
                .foregroundStyle(Color.formPrimaryText)

            Text(album.assetCount.formatted())
                .font(.system(size: 14))
                .foregroundStyle(Color.formSecondaryText)
        }
    }
}

// MARK: - 권한 거부

private extension PhotosPickerView {

    // TODO: 권한 거부 화면 디자인이 나오면 교체
    var deniedView: some View {
        VStack(spacing: 16) {
            Spacer()
            deniedMessage
            openSettingsButton
            Spacer()
        }
    }

    var deniedMessage: some View {
        VStack(spacing: 16) {
            Text("사진 접근 권한이 필요해요")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.formPrimaryText)

            Text("설정에서 사진 접근을 허용하면\n활동 사진을 기록에 추가할 수 있어요")
                .font(.system(size: 14))
                .foregroundStyle(Color.formSecondaryText)
                .multilineTextAlignment(.center)
        }
    }

    var openSettingsButton: some View {
        Button {
            store.send(.openSettingsTapped)
        } label: {
            Text("설정으로 이동")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .frame(height: 44)
                .background(Color.formAccent, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 카메라

private extension PhotosPickerView {

    var cameraBinding: Binding<Bool> {
        Binding(
            get: { store.isCameraPresented },
            set: { if !$0 { store.send(.cameraDismissed) } }
        )
    }

    @ViewBuilder
    var cameraView: some View {
        if CameraPicker.isAvailable {
            CameraPicker(
                onCapture: { store.send(.cameraImageCaptured($0)) },
                onCancel: { store.send(.cameraDismissed) }
            )
            .ignoresSafeArea()
        } else {
            // 시뮬레이터처럼 카메라가 없는 기기에서는 바로 닫아요.
            Color.clear
                .onAppear { store.send(.cameraDismissed) }
        }
    }
}

// MARK: - Color

private extension Color {
    static let photoPickerBanner = Color(red: 0xF0 / 255, green: 0xFC / 255, blue: 0xF3 / 255)
}
