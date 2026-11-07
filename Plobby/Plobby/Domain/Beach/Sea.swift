//
//  Sea.swift
//  Plobby
//
//  Created by dlsundn on 11/5/26.
//

import Foundation

/// 해변이 속한 바다 지역
nonisolated enum Sea: CaseIterable, Sendable {
    case east
    case west
    case south
    case jeju

    var title: String {
        switch self {
        case .east: "동해"
        case .west: "서해"
        case .south: "남해"
        case .jeju: "제주"
        }
    }
}
