//
//  UserClient.swift
//  Plobby
//
//  Created by dlsundn on 11/3/26.
//

import Foundation

import Dependencies
import Supabase

struct UserClient {
    var fetchIsNicknameAvailable: @Sendable (_ nickname: String) async throws -> Bool
}

extension UserClient: DependencyKey {
    static let liveValue: UserClient = {
        .init(
            fetchIsNicknameAvailable: { nickname in
                @Dependency(\.supabaseClient) var supabaseClient

                return try await supabaseClient
                    .rpc("check_nickname", params: CheckNicknameRequestDTO(nickname: nickname))
                    .execute()
                    .value
            }
        )
    }()
}
