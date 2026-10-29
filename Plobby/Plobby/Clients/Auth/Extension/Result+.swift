//
//  Result+.swift
//  Plobby
//
//  Created by 더스틴 on 10/29/26.
//

import AuthenticationServices

extension Result<ASAuthorization, any Error> {
    var appleCredential: Result<AppleCredential, AppleSignInError> {
        switch self {
        case let .success(authorization):
            Result<AppleCredential, AppleSignInError> { () throws(AppleSignInError) in
                try AppleCredential(authorization: authorization)
            }
        case let .failure(error):
            .failure(AppleSignInError(error))
        }
    }
}
