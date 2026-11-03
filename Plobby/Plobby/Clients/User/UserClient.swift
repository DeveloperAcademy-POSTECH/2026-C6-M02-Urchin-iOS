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
    var fetchMyProfile: @Sendable () async throws -> Profile?
    var updateMyProfile: @Sendable (_ nickname: String, _ profileImageKey: String?) async throws -> Profile
    var submitBlock: @Sendable (_ userID: UUID) async throws -> Void
    var removeBlock: @Sendable (_ userID: UUID) async throws -> Void
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
            },
            fetchMyProfile: {
                @Dependency(\.supabaseClient) var supabaseClient

                let userID = try await supabaseClient.auth.session.user.id

                let profile: ProfileResponseDTO? = try await supabaseClient
                    .from("profiles")
                    .select("user_id, nickname, profile_image_key")
                    .eq("user_id", value: userID)
                    .maybeSingle()
                    .execute()
                    .value

                return profile?.toDomain()
            },
            updateMyProfile: { nickname, profileImageKey in
                @Dependency(\.supabaseClient) var supabaseClient

                let userID = try await supabaseClient.auth.session.user.id

                let profile: ProfileResponseDTO = try await supabaseClient
                    .from("profiles")
                    .update(ProfileUpdateRequestDTO(nickname: nickname, profileImageKey: profileImageKey))
                    .eq("user_id", value: userID)
                    .select("user_id, nickname, profile_image_key")
                    .single()
                    .execute()
                    .value

                return profile.toDomain()
            },
            submitBlock: { blockedID in
                @Dependency(\.supabaseClient) var supabaseClient

                let userID = try await supabaseClient.auth.session.user.id

                try await supabaseClient
                    .from("user_blocks")
                    .upsert(
                        UserBlockInsertRequestDTO(blockerID: userID, blockedID: blockedID),
                        onConflict: "blocker_id,blocked_id",
                        returning: .minimal,
                        ignoreDuplicates: true
                    )
                    .execute()
            },
            removeBlock: { blockedID in
                @Dependency(\.supabaseClient) var supabaseClient

                let userID = try await supabaseClient.auth.session.user.id

                try await supabaseClient
                    .from("user_blocks")
                    .delete(returning: .minimal)
                    .eq("blocker_id", value: userID)
                    .eq("blocked_id", value: blockedID)
                    .execute()
            }
        )
    }()
}
