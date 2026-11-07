//
//  AppleSignInError+.swift
//  Plobby
//
//  Created by 더스틴 on 10/29/26.
//

import AuthenticationServices

extension AppleSignInError {
    init(_ error: any Error) {
        let isCanceled = (error as? ASAuthorizationError)?.code == .canceled
        self = isCanceled ? .canceled : .failed
    }
}
