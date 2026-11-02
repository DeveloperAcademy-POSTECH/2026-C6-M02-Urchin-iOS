//
//  BeachClient.swift
//  Plobby
//
//  Created by 이은지 on 11/3/26.
//

import Foundation

import Dependencies
import Supabase

struct BeachClient {
    var fetchBeaches: @Sendable (_ since: Date?) async throws -> [BeachResponseDTO]
}

extension BeachClient: DependencyKey {
    static let liveValue: BeachClient = {
        .init(
            fetchBeaches: { since in
                @Dependency(\.supabaseClient) var supabase

                var query = supabase.from("beaches").select()

                if let since {
                    query = query.gt("updated_at", value: since.ISO8601Format())
                }

                return try await query
                    .order("updated_at")
                    .execute()
                    .value
            }
        )
    }()
}
