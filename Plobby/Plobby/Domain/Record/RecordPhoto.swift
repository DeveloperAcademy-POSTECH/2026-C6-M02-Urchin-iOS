//
//  RecordPhoto.swift
//  Plobby
//
//  Created by 더스틴 on 11/6/26.
//

import Foundation

/// 기록 양식의 사진 한 장. 새로 고른 사진첩 사진이거나, 수정할 때 불러온 이미 올린 사진이에요.
nonisolated enum RecordPhoto: Equatable, Identifiable, Sendable {

    case local(PhotoAsset)
    case remote(storageKey: String, url: URL?)

    var id: String {
        switch self {
        case let .local(asset): "local:\(asset.id)"
        case let .remote(storageKey, _): "remote:\(storageKey)"
        }
    }
}

/// 저장할 때 보내는 사진. 새 사진은 업로드할 JPEG, 기존 사진은 storage key만 보내요.
nonisolated enum RecordPhotoUpload: Equatable, Sendable {

    case new(Data)
    case existing(storageKey: String)
}
