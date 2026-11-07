//
//  PhotoAlbum.swift
//  Plobby
//
//  Created by 더스틴 on 11/4/26.
//

nonisolated struct PhotoAlbum: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let assetCount: Int
    let thumbnailAssetID: PhotoAsset.ID?
}
