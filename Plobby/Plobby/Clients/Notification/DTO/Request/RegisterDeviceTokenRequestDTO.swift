//
//  RegisterDeviceTokenRequestDTO.swift
//  Plobby
//
//  Created by dlsundn on 11/3/26.
//

import Foundation

nonisolated struct RegisterDeviceTokenRequestDTO: Encodable, Sendable {
    let token: String

    enum CodingKeys: String, CodingKey {
        case token = "p_token"
    }
}
