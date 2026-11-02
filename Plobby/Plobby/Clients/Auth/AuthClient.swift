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
    var signUp: @Sendable (_ profile: SignUpProfile) async throws -> Void
    var signOut: @Sendable () async throws -> Void
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
            // TODO: - Supabase 회원가입 요청 API 연동
            signUp: { _ in
                try await Task.sleep(for: .milliseconds(500))

                // 실패 테스트
                // throw URLError(.badServerResponse)
            },
            signOut: {
                @Dependency(\.supabaseClient) var supabase

                try await supabase.auth.signOut(scope: .local)
            }
        )
    }()
}
