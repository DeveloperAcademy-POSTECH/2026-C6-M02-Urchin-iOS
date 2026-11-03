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
    var signUp: @Sendable (_ profile: SignUpProfile) async throws -> Void
    var signOut: @Sendable (_ token: String?) async throws -> Void
    var submitWithdrawalFeedback: @Sendable (_ reason: WithdrawalReason, _ detail: String?) async throws -> Void
    var withdraw: @Sendable (_ reason: WithdrawalReason, _ detail: String?, _ authorizationCode: String) async throws -> Void
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
            },
            withdraw: { reason, detail, authorizationCode in
                @Dependency(\.supabaseClient) var supabase
                @Dependency(\.authClient) var authClient

                try await authClient.submitWithdrawalFeedback(reason, detail)

                try await supabase.functions.invoke(
                    "delete-account",
                    options: FunctionInvokeOptions(
                        body: DeleteAccountRequestDTO(authorizationCode: authorizationCode)
                    )
                )

                try? await supabase.auth.signOut(scope: .local)
            }
        )
    }()
}
