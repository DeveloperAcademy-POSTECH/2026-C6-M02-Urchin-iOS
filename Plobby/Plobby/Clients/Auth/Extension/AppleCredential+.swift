//
//  AppleCredential+.swift
//  Plobby
//
//  Created by 더스틴 on 10/29/26.
//

import AuthenticationServices

extension AppleCredential {
    
    init(authorization: ASAuthorization) throws(AppleSignInError) {
        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = credential.identityToken,
            let idToken = String(data: tokenData, encoding: .utf8)
        else {
            throw .failed
        }
        
        self.init(idToken: idToken)
    }
}
