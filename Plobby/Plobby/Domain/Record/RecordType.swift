//
//  RecordType.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import SwiftUI

nonisolated enum RecordType: String, CaseIterable, Sendable {

    case plobbing
    case plogging
}

nonisolated extension RecordType {
    
    var name: String {
        switch self {
        case .plobbing: "플로빙"
        case .plogging: "플로깅"
        }
    }
    
    var title: String {
        self.name + " 기록하기"
    }
}

@MainActor extension RecordType {
    
    var image: ImageResource {
        switch self {
        case .plobbing: .plobbing
        case .plogging: .plogging
        }
    }
}
