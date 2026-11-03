//
//  WithdrawalFeedbackInsertRequestDTO.swift
//  Plobby
//
//  Created by 이은지 on 11/3/26.
//

nonisolated struct WithdrawalFeedbackInsertRequestDTO: Encodable, Sendable {
    let reason: WithdrawalReason
    let detail: String?
}
