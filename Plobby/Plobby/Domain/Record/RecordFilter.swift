//
//  RecordFilter.swift
//  Plobby
//
//  Created by 이은지 on 11/12/26.
//

import Foundation

enum RecordFilter: Equatable, CaseIterable {
    case all
    case plobbing
    case plogging

    var title: String {
        switch self {
        case .all: "전체"
        case .plobbing: RecordType.plobbing.name
        case .plogging: RecordType.plogging.name
        }
    }

    var recordType: RecordType? {
        switch self {
        case .all: nil
        case .plobbing: .plobbing
        case .plogging: .plogging
        }
    }
}
