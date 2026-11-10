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
    var fetchGoalRecords: @Sendable (_ goal: Goal) async throws -> [RecordSummary]
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
            },
            fetchGoalRecords: { goal in
                @Dependency(\.supabaseClient) var supabase

                async let currentUserIDTask = supabase.currentUserIDIfSignedIn()
                async let hiddenRecordsTask = supabase.hiddenRecords()
                let (currentUserID, hiddenRecords) = try await (currentUserIDTask, hiddenRecordsTask)

                // 활동을 시작한 시각이 목표 기간 안에 있는 기록이에요. 끝 시각은 기간에 포함되지 않아요.
                var query = supabase
                    .from("records")
                    .select(RecordSummaryResponseDTO.selectQuery)
                    .gte("started_at", value: goal.startsAt.ISO8601Format())
                    .lt("started_at", value: goal.endsAt.ISO8601Format())
                    .is("deleted_at", value: nil)
                    .excluding(hiddenRecords)

                if let currentUserID {
                    query = query.eq("my_like.user_id", value: currentUserID)
                }

                let responseDTOs: [RecordSummaryResponseDTO] = try await query
                    .order("created_at", ascending: false)
                    .execute()
                    .value

                return responseDTOs.compactMap {
                    $0.toDomain(
                        currentUserID: currentUserID,
                        photoURL: supabase.recordPhotoURL,
                        profileImageURL: supabase.profileImageURL
                    )
                }
            }
        )
    }()
}
