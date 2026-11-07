//
//  WithdrawalFeedbackInsertRequestDTO.swift
//  Plobby
//
//  Created by 이은지 on 11/3/26.
//

nonisolated struct WithdrawalFeedbackInsertRequestDTO: Encodable, Sendable {
    let reason: Reason
    let detail: String?
}

nonisolated extension WithdrawalFeedbackInsertRequestDTO {

    /// 사유를 고르지 않고 기타만 입력했으면 `other`로 보내요.
    init(from reason: WithdrawalReason?, detail: String?) {
        self.init(reason: reason.map(Reason.init(from:)) ?? .other, detail: detail)
    }

    enum Reason: String, Encodable, Sendable {
        case noLongerActive = "no_longer_active"
        case hardToRecord = "hard_to_record"
        case unmetExpectation = "unmet_expectation"
        case lackOfMapInfo = "lack_of_map_info"
        case slowOrBuggy = "slow_or_buggy"
        case other

        init(from reason: WithdrawalReason) {
            switch reason {
            case .noLongerActive: self = .noLongerActive
            case .hardToRecord: self = .hardToRecord
            case .unmetExpectation: self = .unmetExpectation
            case .lackOfMapInfo: self = .lackOfMapInfo
            case .slowOrBuggy: self = .slowOrBuggy
            }
        }
    }
}
