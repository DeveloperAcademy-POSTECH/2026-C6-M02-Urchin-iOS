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
    var signInWithApple: @Sendable (_ idToken: String, _ nonce: String) async throws -> AuthUser
    var fetchIsMember: @Sendable (_ userID: UUID) async throws -> Bool
    var signOut: @Sendable () async throws -> Void
}

extension AuthClient: DependencyKey {
    static let liveValue: AuthClient = {
        .init(
            signInWithApple: { idToken, nonce in
                @Dependency(\.supabaseClient) var supabase

                let session = try await supabase.auth.signInWithIdToken(
                    credentials: OpenIDConnectCredentials(provider: .apple, idToken: idToken, nonce: nonce)
                )
                return AuthUser(id: session.user.id, email: session.user.email)
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
            signOut: {
                @Dependency(\.supabaseClient) var supabase

                try await supabase.auth.signOut(scope: .local)
            }
        )
    }()
}
