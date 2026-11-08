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
            }
        )
    }()
}
