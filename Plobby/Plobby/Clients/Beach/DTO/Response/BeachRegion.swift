//
//  BeachRegion.swift
//  Plobby
//
//  Created by 이은지 on 11/3/26.
//

enum BeachRegion: String, Decodable, CaseIterable {
    case east, west, south, jeju

    var displayName: String {
        switch self {
        case .east: "동해"
        case .west: "서해"
        case .south: "남해"
        case .jeju: "제주"
        }
    }
}
