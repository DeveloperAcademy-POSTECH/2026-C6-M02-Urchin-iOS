//
//  PhotosPickerView.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import SwiftUI

import ComposableArchitecture

struct PhotosPickerView: View {

    // MARK: - Properties

    let store: StoreOf<PhotosPickerFeature>

    private let columnCount = 3
    private let gridSpacing: CGFloat = 1
    private let albumThumbnailLength: CGFloat = 48.scaled

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            navigationBar
            content
        }
        .background(Color(.gray0))
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
            if store.purpose != .profile {
                guideBanner
            }
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
        .padding(.horizontal, 20.scaled)
        .frame(height: 56.scaled)
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

    var albumToggleLabel: some View {
        HStack(spacing: 8.scaled) {
            Color.clear
                .frame(width: 24.scaled, height: 24.scaled)

            Text(albumTitle)
                .plobbyFont(.cardTitle)
                .foregroundStyle(Color(.textPrimary))

            Image(
                systemName: store.isAlbumListExpanded
                ? "chevron.up"
                : "chevron.down"
            )
            .plobbyFont(.cardTitle)
            .foregroundStyle(Color(.textPrimary))
            .frame(width: 24.scaled, height: 24.scaled)
        }
        .frame(height: 44.scaled)
        .contentShape(Rectangle())
    }

    var closeButton: some View {
        HStack {
            Button {
                store.send(.closeTapped)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17.scaled, weight: .medium))
                    .foregroundStyle(Color(.textPrimary))
                    .frame(width: 24.scaled, height: 24.scaled)
            }
            .accessibilityLabel("닫기")

            Spacer()
        }
    }
}

// MARK: - 안내 배너

private extension PhotosPickerView {

    var guideBanner: some View {
        HStack(spacing: 12.scaled) {
            Image(systemName: "plus.square.on.square")
                .font(.system(size: 16.scaled))
                .foregroundStyle(Color(.textPrimary))
                .frame(width: 20.scaled, height: 20.scaled)

            Text("최대 \(PhotoSelection.maxCount)장까지 추가할 수 있어요")
                .plobbyFont(.notification)
                .foregroundStyle(Color(.textPrimary))

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20.scaled)
        .frame(height: 56.scaled)
        .background(Color(.currentBrandSubtle))
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
        .background(Color(.gray0))
        .plobbyToast(store.toast.toastMessage)
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
                .background(Color(.gray0))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("카메라로 촬영")
    }

    var cameraCellLabel: some View {
        VStack(spacing: 4.scaled) {
            Image(systemName: "camera.fill")
                .font(.system(size: 18.scaled))
                .foregroundStyle(Color(.textPrimary))
                .frame(width: 24.scaled, height: 24.scaled)

            Text("카메라")
                .plobbyFont(.metadata)
                .foregroundStyle(Color(.textPrimary))
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
            Color(.neutralBlack).opacity(0.4)
        }
    }

    func selectionBadge(order: Int?) -> some View {
        Group {
            if let order {
                selectedBadge(order: order)
            } else {
                emptyBadge
            }
        }
        .frame(width: 24.scaled, height: 24.scaled)
        .shadow(color: Color(.neutralBlack).opacity(0.12), radius: 6, x: 4, y: 4)
        .padding(.top, 6.scaled)
        .padding(.trailing, 9.scaled)
    }

    func selectedBadge(order: Int) -> some View {
        Text("\(order)")
            .plobbyFont(.actionLabel)
            .foregroundStyle(Color(.textPrimary))
            .frame(width: 24.scaled, height: 24.scaled)
            .background(Color(.gray0), in: Circle())
    }

    var emptyBadge: some View {
        Circle()
            .fill(Color(.neutralBlack).opacity(0.2))
            .overlay {
                Circle()
                    .strokeBorder(Color(.gray0), lineWidth: 1)
            }
    }
}

// MARK: - 하단 버튼

private extension PhotosPickerView {

    var bottomButton: some View {
        Group {
            if store.purpose == .profile {
                PlobbyButton(text: "사진 추가") {
                    store.send(.bottomButtonTapped)
                }
                .disabled(store.isSkip)
            } else {
                PlobbyButton(
                    text: store.isSkip ? "나중에 추가" : "다음",
                    style: store.isSkip ? .alternative : .default
                ) {
                    store.send(.bottomButtonTapped)
                }
            }
        }
        .padding(.horizontal, 20.scaled)
        .padding(.vertical, 24.scaled)
        .background(Color(.gray0))
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
            .fill(Color(.currentWarmBorder))
            .frame(height: 1)
            .padding(.horizontal, 20.scaled)
    }

    func albumRow(_ album: PhotoAlbum) -> some View {
        Button {
            store.send(.albumSelected(album.id))
        } label: {
            HStack(spacing: 16.scaled) {
                albumThumbnail(album)
                albumTitleAndCount(album)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20.scaled)
            .frame(height: 80.scaled)
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
                Color(.gray50)
                    .frame(width: albumThumbnailLength, height: albumThumbnailLength)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8.scaled))
    }

    func albumTitleAndCount(_ album: PhotoAlbum) -> some View {
        VStack(alignment: .leading, spacing: 2.scaled) {
            Text(album.title)
                .plobbyFont(.cardTitle)
                .foregroundStyle(Color(.textPrimary))

            Text(album.assetCount.formatted())
                .plobbyFont(.label)
                .foregroundStyle(Color(.textSecondary))
        }
    }
}

// MARK: - 권한 거부

private extension PhotosPickerView {

    // TODO: 권한 거부 화면 디자인이 나오면 교체
    var deniedView: some View {
        VStack(spacing: 16.scaled) {
            Spacer()
            deniedMessage
            openSettingsButton
            Spacer()
        }
    }

    var deniedMessage: some View {
        VStack(spacing: 16.scaled) {
            Text("사진 접근 권한이 필요해요")
                .plobbyFont(.cardTitle)
                .foregroundStyle(Color(.textPrimary))

            Text("설정에서 사진 접근을 허용하면\n활동 사진을 기록에 추가할 수 있어요")
                .plobbyFont(.label)
                .foregroundStyle(Color(.textSecondary))
                .multilineTextAlignment(.center)
        }
    }

    var openSettingsButton: some View {
        Button {
            store.send(.openSettingsTapped)
        } label: {
            Text("설정으로 이동")
                .plobbyFont(.notification)
                .foregroundStyle(Color(.gray0))
                .padding(.horizontal, 20.scaled)
                .frame(height: 44.scaled)
                .background(Color(.green500), in: RoundedRectangle(cornerRadius: 8.scaled))
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
            Color.clear
                .onAppear { store.send(.cameraDismissed) }
        }
    }
}
