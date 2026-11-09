//
//  HomeSceneStage.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import Foundation

/// 홈 장면의 한 단계예요. 아래로 스크롤할 때마다 한 단계씩 넘어가고, 일부 단계는 이어서 자동으로 넘어가요.
enum HomeSceneStage: Equatable, Sendable {
    /// 그날의 해변(바닷속)에 도착했어요. 쓰레기가 흩어져 있어요.
    case arrived(day: Int)
    /// 쓰레기가 봉투(수거망)로 들어가는 중이에요.
    case collecting(day: Int)
    /// 그날 수거가 끝나고 수거량이 보여요.
    case collected(day: Int)
    /// 모든 날짜를 지난 마무리 연출이에요.
    /// - 플로깅: 0 수거대 도착 → 1 수거 결과
    /// - 플로빙: 0 더 깊이 잠수 → 1 수면으로 이동 → 2 수거 결과
    case finale(step: Int)

    func day(lastDay: Int) -> Int {
        switch self {
        case let .arrived(day), let .collecting(day), let .collected(day): day
        case .finale: lastDay
        }
    }

    var isCollected: Bool {
        if case .collected = self { return true }
        return false
    }
}

extension RecordType {

    /// 마무리 연출의 마지막(수거 결과) 단계예요.
    var resultStep: Int {
        switch self {
        case .plogging: 1
        case .plobbing: 2
        }
    }

    /// 앞으로 스크롤했을 때 차례로 보여줄 단계예요. 첫 단계 뒤로는 자동으로 이어져요.
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

    /// 뒤로 스크롤했을 때 돌아갈 단계예요.
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
