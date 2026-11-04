//
//  PhotoAsset.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import Foundation

nonisolated struct PhotoAsset: Equatable, Identifiable, Sendable {
    let id: String
    let imageData: Data
}
