//
//  AuthClient.swift
//  Plobby
//
//  Created by 더스틴 on 10/27/26.
//

import Foundation

import Dependencies
import Supabase

struct AuthClient {
    var signInWithApple: @Sendable (_ idToken: String, _ nonce: String, _ fullName: String?) async throws -> AuthUser
    var fetchIsMember: @Sendable (_ userID: UUID) async throws -> Bool
    var fetchIsNicknameAvailable: @Sendable (_ nickname: String) async throws -> Bool
    var signUp: @Sendable (_ profile: SignUpProfile) async throws -> Void
    var signOut: @Sendable (_ token: String?) async throws -> Void
    var submitWithdrawalFeedback: @Sendable (_ reason: WithdrawalReason, _ detail: String?) async throws -> Void
}

extension AuthClient: DependencyKey {
    static let liveValue: AuthClient = {
        .init(
            signInWithApple: { idToken, nonce, fullName in
                @Dependency(\.supabaseClient) var supabase

                let session = try await supabase.auth.signInWithIdToken(
                    credentials: OpenIDConnectCredentials(provider: .apple, idToken: idToken, nonce: nonce)
                )

                if let fullName {
                    _ = try? await supabase.auth.update(
                        user: UserAttributes(data: ["full_name": .string(fullName)])
                    )
                }

                return AuthUser(
                    id: session.user.id,
                    email: session.user.email,
                    fullName: fullName ?? session.user.userMetadata["full_name"]?.stringValue
                )
            },
            fetchIsMember: { userID in
                @Dependency(\.supabaseClient) var supabase

                let count = try await supabase
                    .from("profiles")
                    .select("user_id", head: true, count: .exact)
                    .eq("user_id", value: userID)
                    .execute()
                    .count

                return (count ?? 0) > 0
            },
            // TODO: - Supabase 닉네임 중복 확인 API 연동
            fetchIsNicknameAvailable: { _ in
                try await Task.sleep(for: .milliseconds(500))

                return true   // 사용 가능
                // return false   // 중복
            },
            signUp: { profile in
                @Dependency(\.supabaseClient) var supabase

                try await supabase
                    .rpc("complete_signup", params: CompleteSignupRequestDTO(from: profile))
                    .execute()
            },
            signOut: { token in
                @Dependency(\.supabaseClient) var supabase

                if let token {
                    do {
                        try await supabase
                            .from("device_tokens")
                            .delete()
                            .eq("token", value: token)
                            .execute()
                    } catch {
                        PlobbyLogger.error(error)
                    }
                }

                try await supabase.auth.signOut(scope: .local)
            },
            submitWithdrawalFeedback: { reason, detail in
                @Dependency(\.supabaseClient) var supabase

                let trimmed = detail?.trimmingCharacters(in: .whitespacesAndNewlines)
                let detailToSave = (reason == .other && trimmed?.isEmpty == false) ? trimmed : nil

                try await supabase
                    .from("withdrawal_feedback")
                    .insert(WithdrawalFeedbackInsertRequestDTO(reason: reason, detail: detailToSave))
                    .execute()
            }
        )
    }()
}
