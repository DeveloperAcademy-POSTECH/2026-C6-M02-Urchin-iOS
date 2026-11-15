//
//  WithdrawalReason.swift
//  Plobby
//
//  Created by 이은지 on 11/3/26.
//

/// 회원 탈퇴 사유
nonisolated enum WithdrawalReason: CaseIterable, Sendable {
    case noLongerActive
    case hardToRecord
    case unmetExpectation
    case lackOfMapInfo
    case slowOrBuggy

    var title: String {
        switch self {
        case .noLongerActive: "플로깅·플로빙 활동을 더 이상 하지 않아요"
        case .hardToRecord: "활동을 기록하기가 번거로워요"
        case .unmetExpectation: "기록 기능이 기대했던 것과 달라요"
        case .lackOfMapInfo: "지도에서 원하는 정보를 찾기 어려워요"
        case .slowOrBuggy: "앱이 느리거나 오류가 잦아요"
        }
    }
}
