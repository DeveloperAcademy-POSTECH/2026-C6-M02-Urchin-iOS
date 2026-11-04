//
//  RecordType.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

nonisolated enum RecordType: String, Sendable {

    case plogging
    case plobbing
}

nonisolated extension RecordType {
    
    var name: String {
        switch self {
        case .plogging: "플로깅"
        case .plobbing: "플로빙"
        }
    }
    
    var title: String {
        self.name + " 기록하기"
    }
}
