//
//  SharedKey+.swift
//  Plobby
//
//  Created by dlsundn on 11/4/26.
//

import ComposableArchitecture

extension SharedKey where Self == InMemoryKey<MembershipStatus>.Default {

    /// 회원 여부. 값 변경은 AppFeature에서만 해요.
    static var membershipStatus: Self { Self[.inMemory("membershipStatus"), default: .guest] }
}
