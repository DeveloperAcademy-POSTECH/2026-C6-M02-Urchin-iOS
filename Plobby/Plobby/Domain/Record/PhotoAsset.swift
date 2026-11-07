//
//  PhotoAsset.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

/// 갤러리 사진 한 장
/// 원본 데이터를 State에 넣으면 메모리와 비교 비용이 커지므로 식별자(PHAsset.localIdentifier)만 비교
nonisolated struct PhotoAsset: Equatable, Identifiable, Sendable {
    let id: String
}
