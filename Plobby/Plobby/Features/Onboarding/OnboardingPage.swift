//
//  OnboardingPage.swift
//  Plobby
//
//  Created by 이은지 on 10/30/26.
//

/// 온보딩 4단계: 목표 → 기록 → 지도 → 컬렉션
enum OnboardingPage: Int, CaseIterable {

    case goal, record, map, collection

    var number: Int {
        rawValue + 1
    }

    var next: OnboardingPage? {
        OnboardingPage(rawValue: rawValue + 1)
    }

    var previous: OnboardingPage? {
        OnboardingPage(rawValue: rawValue - 1)
    }

    var isLast: Bool {
        next == nil
    }
}

extension OnboardingPage {

    var title: String {
        switch self {
        case .goal: "바다를 위한 목표,\n함께 이뤄요"
        case .record: "내가 기록한 개수만큼\n목표에 가까워져요"
        case .map: "다른 사람들의 기록을\n지도에서 살펴봐요"
        case .collection: "내가 남긴 기록은\n특별한 컬렉션이 돼요"
        }
    }

    var description: String {
        switch self {
        case .goal: "해변과 바닷속 쓰레기를 주우며\n우리가 사랑하는 바다를 지켜요"
        case .record: "플로깅과 플로빙 활동을 앱에 남겨보세요\n나의 실천이 모두의 목표에 더해져요"
        case .map: "누가, 어디서, 어떤 쓰레기를\n주웠는지 한눈에 볼 수 있어요"
        case .collection: "종류별로 모인 카드를 뒤집어 보세요\n바다 생물에게 어떤 도움을 줬는지 알려줄게요"
        }
    }

    /// 플로깅/플로빙 탭으로 예시 화면을 바꿔 볼 수 있는 단계예요
    var showsActivityTabs: Bool {
        switch self {
        case .goal, .record: true
        case .map, .collection: false
        }
    }
}
