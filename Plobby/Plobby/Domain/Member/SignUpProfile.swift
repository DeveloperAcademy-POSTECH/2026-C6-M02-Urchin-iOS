//
//  SignUpProfile.swift
//  Plobby
//
//  Created by 이은지 on 10/31/26.
//

import Foundation

struct SignUpProfile: Equatable {
    let userID: UUID
    let profileImage: Data?
    let name: String?
    let nickname: String
    let favoriteBeachIDs: [UUID]
}
