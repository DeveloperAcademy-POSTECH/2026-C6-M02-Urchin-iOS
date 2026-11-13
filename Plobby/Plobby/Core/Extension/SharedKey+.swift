//
//  SharedKey+.swift
//  Plobby
//
//  Created by dlsundn on 11/4/26.
//

import Foundation

import ComposableArchitecture

extension SharedKey where Self == InMemoryKey<MembershipStatus>.Default {

    static var membershipStatus: Self { Self[.inMemory("membershipStatus"), default: .guest] }
}

extension SharedKey where Self == FileStorageKey<[Beach]>.Default {

    static var beaches: Self {
        Self[
            .fileStorage(
                .applicationSupportDirectory.appending(component: "beaches-v2.json"),
                decode: BeachStorageDTO.decode,
                encode: BeachStorageDTO.encode
            ),
            default: BeachStorageDTO.bundledBeaches
        ]
    }
}

extension SharedKey where Self == AppStorageKey<Date?>.Default {

    /// 해변 목록을 마지막으로 동기화한 시각. 값 변경은 AppFeature에서만 해요.
    static var beachesSyncedAt: Self { Self[.appStorage("beachesSyncedAt"), default: nil] }
}

extension SharedKey where Self == AppStorageKey<Bool>.Default {

    /// 이 기기에서 푸시를 받을지 여부. 설정의 알림 토글로 바꿔요.
    static var isPushEnabled: Self { Self[.appStorage("isPushEnabled"), default: true] }
}

extension SharedKey where Self == AppStorageKey<Bool>.Default {

    /// 이 기기에서 온보딩을 끝까지 본 적 있는지 여부. 본 적 있으면 다음 실행부터 로그인 화면을 보여줘요.
    static var hasSeenOnboarding: Self { Self[.appStorage("hasSeenOnboarding"), default: false] }
}

extension SharedKey where Self == InMemoryKey<[Beach]>.Default {

    /// 로그인한 사용자의 관심 해변. 홈과 지도 탭이 함께 써요.
    static var favoriteBeaches: Self { Self[.inMemory("favoriteBeaches"), default: []] }
}

extension SharedKey where Self == FileStorageKey<[Beach]>.Default {

    /// 지도 탭에서 최근 고른 해변. 최신순이에요.
    static var recentSearches: Self {
        Self[
            .fileStorage(
                .applicationSupportDirectory.appending(component: "recent-searches.json"),
                decode: BeachStorageDTO.decode,
                encode: BeachStorageDTO.encode
            ),
            default: []
        ]
    }
}

extension SharedKey where Self == FileStorageKey<Set<String>>.Default {

    /// 이 기기에서 "다음 목표 보기"를 눌러 넘긴 공통 목표예요. 값은 `Goal.dismissalKey`예요.
    /// 넘긴 목표는 축하(또는 아쉬움) 이모지를 다시 띄우지 않고, 다음 목표가 있으면 홈에서 건너뛰어요.
    static var dismissedGoalKeys: Self {
        Self[.fileStorage(.applicationSupportDirectory.appending(component: "dismissed-goals.json")), default: []]
    }
}
