//
//  AuthUser.swift
//  Plobby
//
//  Created by 더스틴 on 10/27/26.
//

import Foundation

struct AuthUser: Equatable {
    let id: UUID
    let email: String?
    let fullName: String?
}
