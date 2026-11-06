//
//  WithdrawalReason.swift
//  Plobby
//
//  Created by 이은지 on 11/3/26.
//

// TODO: 서버 withdrawal_feedback.reason 값을 아래 rawValue와 맞추기
nonisolated enum WithdrawalReason: String, CaseIterable, Encodable, Sendable {
    case noLongerActive = "no_longer_active"
    case hardToRecord = "hard_to_record"
    case unmetExpectation = "unmet_expectation"
    case lackOfMapInfo = "lack_of_map_info"
    case slowOrBuggy = "slow_or_buggy"
}
