//
//  SharedKey+.swift
//  Plobby
//
//  Created by dlsundn on 11/4/26.
//

import Foundation

import ComposableArchitecture

extension SharedKey where Self == InMemoryKey<MembershipStatus>.Default {

    /// 회원 여부. 값 변경은 AppFeature에서만 해요.
    static var membershipStatus: Self { Self[.inMemory("membershipStatus"), default: .guest] }
}

extension SharedKey where Self == FileStorageKey<[Beach]>.Default {

    /// 전체 해변 목록. 처음엔 번들 JSON, 앱 시작 시 서버 데이터로 교체해요. 값 변경은 AppFeature에서만 해요.
    static var beaches: Self {
        Self[
            .fileStorage(.applicationSupportDirectory.appending(component: "beaches.json")),
            default: Beach.all
        ]
    }
}
