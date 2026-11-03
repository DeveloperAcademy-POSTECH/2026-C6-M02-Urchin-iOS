//
//  CheckNicknameRequestDTO.swift
//  Plobby
//
//  Created by dlsundn on 11/3/26.
//

import Foundation

nonisolated struct CheckNicknameRequestDTO: Encodable, Sendable {
    let nickname: String

    enum CodingKeys: String, CodingKey {
        case nickname = "p_nickname"
    }
}
