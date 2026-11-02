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
    var fetchFavoriteBeaches: @Sendable () async throws -> [FavoriteBeachResponseDTO]
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
            },
            fetchFavoriteBeaches: {
                @Dependency(\.supabaseClient) var supabase

                let userID = try await supabase.auth.session.user.id

                return try await supabase
                    .from("favorite_beaches")
                    .select("beach_id, created_at, beach:beaches(*)")
                    .eq("user_id", value: userID)
                    .order("created_at")
                    .execute()
                    .value
            }
        )
    }()
}
