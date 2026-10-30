//
//  AuthClient.swift
//  Plobby
//
//  Created by 더스틴 on 10/27/26.
//

import Dependencies
import Supabase

struct AuthClient {
    var signInWithApple: @Sendable (_ idToken: String, _ nonce: String) async throws -> AuthUser
}

extension AuthClient: DependencyKey {
    static let liveValue: AuthClient = {
        .init { idToken, nonce in
            @Dependency(\.supabaseClient) var supabase
            
            let session = try await supabase.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(provider: .apple, idToken: idToken, nonce: nonce)
            )
            return AuthUser(id: session.user.id, email: session.user.email)
        }
    }()
}
