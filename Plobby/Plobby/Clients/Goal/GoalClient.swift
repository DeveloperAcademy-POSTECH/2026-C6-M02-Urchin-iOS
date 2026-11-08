//
//  GoalClient.swift
//  Plobby
//
//  Created by dlsundn on 11/9/26.
//

import Foundation

import Dependencies
import Supabase

struct GoalClient {
    var fetchCurrentGoal: @Sendable (_ now: Date) async throws -> Goal?
    var fetchGoals: @Sendable (_ now: Date) async throws -> [Goal]
    var fetchDailyProgresses: @Sendable (_ goalID: UUID, _ recordType: RecordType) async throws -> [GoalDailyProgress]
    var fetchTrashSummaries: @Sendable (_ goalID: UUID, _ recordType: RecordType) async throws -> [GoalTrashSummary]
    var fetchParticipants: @Sendable (_ goalID: UUID, _ recordType: RecordType) async throws -> [GoalParticipant]
}

extension GoalClient: DependencyKey {
    static let liveValue: GoalClient = {
        .init(
            fetchCurrentGoal: { now in
                @Dependency(\.supabaseClient) var supabase

                let responseDTOs: [GoalProgressResponseDTO] = try await supabase
                    .from("goal_progress")
                    .select()
                    .lte("starts_at", value: now.ISO8601Format())
                    .gt("ends_at", value: now.ISO8601Format())
                    .limit(1)
                    .execute()
                    .value

                return responseDTOs.first?.toDomain()
            },
            fetchGoals: { now in
                @Dependency(\.supabaseClient) var supabase

                let responseDTOs: [GoalProgressResponseDTO] = try await supabase
                    .from("goal_progress")
                    .select()
                    .lte("starts_at", value: now.ISO8601Format())
                    .order("starts_at", ascending: false)
                    .execute()
                    .value

                return responseDTOs.map { $0.toDomain() }
            },
            fetchDailyProgresses: { goalID, recordType in
                @Dependency(\.supabaseClient) var supabase

                let responseDTOs: [GoalDailyProgressResponseDTO] = try await supabase
                    .from("goal_daily_progress")
                    .select("day, collected_count, participant_count")
                    .eq("goal_id", value: goalID)
                    .eq("record_type", value: recordType.rawValue)
                    .order("day")
                    .execute()
                    .value

                return responseDTOs.compactMap { $0.toDomain() }
            },
            fetchTrashSummaries: { goalID, recordType in
                @Dependency(\.supabaseClient) var supabase

                let responseDTOs: [GoalTrashSummaryResponseDTO] = try await supabase
                    .from("goal_trash_summary")
                    .select("trash_code, collected_count")
                    .eq("goal_id", value: goalID)
                    .eq("record_type", value: recordType.rawValue)
                    .order("collected_count", ascending: false)
                    .execute()
                    .value

                return responseDTOs.compactMap { $0.toDomain() }
            },
            fetchParticipants: { goalID, recordType in
                @Dependency(\.supabaseClient) var supabase

                async let hiddenRecords = supabase.hiddenRecords()
                async let responseDTOs: [GoalParticipantResponseDTO] = supabase
                    .from("goal_participants")
                    .select("user_id, nickname, profile_image_key, collected_count")
                    .eq("goal_id", value: goalID)
                    .eq("record_type", value: recordType.rawValue)
                    .order("collected_count", ascending: false)
                    .order("nickname")
                    .execute()
                    .value

                let blockedUserIDs = Set(try await hiddenRecords.userIDs)

                return try await responseDTOs.map {
                    $0.toDomain(
                        isBlocked: blockedUserIDs.contains($0.userID),
                        profileImageURL: supabase.profileImageURL
                    )
                }
            }
        )
    }()
}
