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

    func forwardStages(from stage: HomeSceneStage, lastDay: Int) -> [HomeSceneStage] {
        switch (self, stage) {
        case let (_, .arrived(day)):
            [.collecting(day: day), .collected(day: day)]
        case (_, .collecting):
            []
        case let (_, .collected(day)) where day < lastDay:
            [.arrived(day: day + 1)]
        case (.plogging, .collected):
            [.finale(step: 0), .finale(step: 1)]
        case (.plobbing, .collected):
            [.finale(step: 0)]
        case (.plobbing, .finale(step: 0)):
            [.finale(step: 1), .finale(step: 2)]
        case (_, .finale):
            []
        }
    }

    func backwardStages(from stage: HomeSceneStage, lastDay: Int) -> [HomeSceneStage] {
        switch stage {
        case let .arrived(day) where day > 0:
            [.collected(day: day - 1)]
        case .arrived, .collecting:
            []
        case let .collected(day):
            [.arrived(day: day)]
        case .finale:
            [.collected(day: lastDay)]
        }
    }
}
