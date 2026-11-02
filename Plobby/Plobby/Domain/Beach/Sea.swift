//
//  Sea.swift
//  Plobby
//
//  Created by 이은지 on 11/1/26.
//

import Foundation

enum Sea: CaseIterable {

    case all, east, west, south, jeju

    var title: String {
        switch self {
        case .all: "전체"
        case .east: "동해"
        case .west: "서해"
        case .south: "남해"
        case .jeju: "제주"
        }
    }
}
