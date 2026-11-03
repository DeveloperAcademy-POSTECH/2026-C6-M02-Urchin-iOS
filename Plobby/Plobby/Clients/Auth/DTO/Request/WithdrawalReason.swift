//
//  WithdrawalReason.swift
//  Plobby
//
//  Created by 이은지 on 11/3/26.
//

nonisolated enum WithdrawalReason: String, Encodable, Sendable {
    case notUseful = "not_useful"
    case hardToUse = "hard_to_use"
    case fewActivities = "few_activities"
    case privacy
    case newAccount = "new_account"
    case other
}
