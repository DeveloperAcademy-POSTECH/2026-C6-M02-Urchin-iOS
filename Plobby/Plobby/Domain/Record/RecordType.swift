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

// MARK: - Functions

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
    
    var resultTitle: String {
        switch self {
        case .plogging: "수거대에 모은 쓰레기"
        case .plobbing: "배에 실은 쓰레기"
        }
    }
    
    var resultStep: Int {
        switch self {
        case .plogging: 1
        case .plobbing: 2
        }
    }
}
