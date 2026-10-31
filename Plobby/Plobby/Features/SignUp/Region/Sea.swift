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

    // TODO: - beaches 데이터 연동
    var regions: [String] {
        switch self {
        case .all: ["전국 전체"]
        case .east: ["강릉", "속초", "포항"]
        case .west: ["태안", "보령", "군산"]
        case .south: ["부산", "여수", "거제"]
        case .jeju: ["제주시", "서귀포시"]
        }
    }
}
