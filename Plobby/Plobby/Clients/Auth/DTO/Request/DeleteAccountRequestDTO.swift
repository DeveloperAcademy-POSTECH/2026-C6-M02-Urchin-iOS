//
//  DeleteAccountRequestDTO.swift
//  Plobby
//
//  Created by 이은지 on 11/3/26.
//

nonisolated struct DeleteAccountRequestDTO: Encodable, Sendable {
    let authorizationCode: String
}
