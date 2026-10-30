//
//  SignInResult.swift
//  Plobby
//
//  Created by 이은지 on 10/30/26.
//

import Foundation

enum SignInResult {
    case member(AuthUser)
    case newUser(AuthUser, fullName: String?)
}
