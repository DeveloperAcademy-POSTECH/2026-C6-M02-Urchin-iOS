//
//  MembershipStatus.swift
//  Plobby
//
//  Created by 이은지 on 10/30/26.
//

import Foundation

enum MembershipStatus: Equatable {
    case member(AuthUser)
    case guest
}
