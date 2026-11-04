//
//  PhotoThumbnailView.swift
//  Plobby
//
//  Created by 더스틴 on 11/4/26.
//

import SwiftUI

import Dependencies

/// 사진 식별자로 썸네일을 불러와 그려요. 사진 선택 그리드와 기록 양식에서 함께 써요.
struct PhotoThumbnailView: View {

    // MARK: - Properties

    let assetID: PhotoAsset.ID
    let size: CGSize

    @Dependency(\.photoLibraryClient) private var photoLibraryClient
    @Environment(\.displayScale) private var displayScale
    @State private var image: UIImage?

    // MARK: - Body

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color(.systemGray6)
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
        .task(id: assetID) {
            let pixelSize = CGSize(width: size.width * displayScale, height: size.height * displayScale)
            image = await photoLibraryClient.thumbnail(assetID, pixelSize)
        }
    }
}
