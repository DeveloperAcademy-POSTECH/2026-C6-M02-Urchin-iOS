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
    var fetchRecordCounts: @Sendable () async throws -> [UUID: Int]
    var fetchBeachRecords: @Sendable (_ beachID: UUID, _ recordType: RecordType?) async throws -> [BeachRecord]
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
                    .order("name")
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
            },
            fetchRecordCounts: {
                @Dependency(\.supabaseClient) var supabase

                let hiddenRecords = try await supabase.hiddenRecords()

                let records: [BeachIDResponse] = try await supabase
                    .from("records")
                    .select("beach_id")
                    .is("deleted_at", value: nil)
                    .excluding(hiddenRecords)
                    .execute()
                    .value

                return records.reduce(into: [:]) { counts, record in
                    counts[record.beachID, default: 0] += 1
                }
            },
            fetchBeachRecords: { beachID, recordType in
                @Dependency(\.supabaseClient) var supabase

                let hiddenRecords = try await supabase.hiddenRecords()

                var query = supabase
                    .from("records")
                    .select(BeachRecordResponseDTO.selectQuery)
                    .eq("beach_id", value: beachID)
                    .is("deleted_at", value: nil)
                    .excluding(hiddenRecords)

                if let recordType {
                    query = query.eq("record_type", value: recordType.rawValue)
                }

                let responseDTOs: [BeachRecordResponseDTO] = try await query
                    .order("created_at", ascending: false)
                    .execute()
                    .value

                let imageBucket = supabase.storage.from(StorageBucket.image)
                let profileBucket = supabase.storage.from(StorageBucket.profile)

                return responseDTOs.compactMap {
                    $0.toDomain(
                        photoURL: { try? imageBucket.getPublicURL(path: $0) },
                        profileImageURL: { try? profileBucket.getPublicURL(path: $0) }
                    )
                }
            }
        )
    }()
}

private nonisolated struct BeachIDResponse: Decodable, Sendable {
    
    let beachID: UUID

    enum CodingKeys: String, CodingKey {
        case beachID = "beach_id"
    }
}
