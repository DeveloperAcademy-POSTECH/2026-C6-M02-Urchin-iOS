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
    var fetchBeaches: @Sendable (_ since: Date?) async throws -> [Beach]
    var fetchFavoriteBeaches: @Sendable () async throws -> [Beach]
    var submitFavoriteBeach: @Sendable (_ beachID: UUID) async throws -> Void
    var removeFavoriteBeach: @Sendable (_ beachID: UUID) async throws -> Void
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

                let beaches: [BeachResponseDTO] = try await query
                    .order("updated_at")
                    .execute()
                    .value

                return beaches.map { $0.toDomain() }
            },
            fetchFavoriteBeaches: {
                @Dependency(\.supabaseClient) var supabase

                let userID = try await supabase.auth.session.user.id

                let favoriteBeaches: [FavoriteBeachResponseDTO] = try await supabase
                    .from("favorite_beaches")
                    .select("beach_id, created_at, beach:beaches(*)")
                    .eq("user_id", value: userID)
                    .order("created_at")
                    .execute()
                    .value

                return favoriteBeaches.map { $0.beach.toDomain() }
            },
            submitFavoriteBeach: { beachID in
                @Dependency(\.supabaseClient) var supabase

                let userID = try await supabase.auth.session.user.id

                try await supabase
                    .from("favorite_beaches")
                    .insert(FavoriteBeachInsertRequestDTO(userID: userID, beachID: beachID))
                    .execute()
            },
            removeFavoriteBeach: { beachID in
                @Dependency(\.supabaseClient) var supabase

                let userID = try await supabase.auth.session.user.id

                try await supabase
                    .from("favorite_beaches")
                    .delete()
                    .eq("user_id", value: userID)
                    .eq("beach_id", value: beachID)
                    .execute()
            }
        )
    }()
}
