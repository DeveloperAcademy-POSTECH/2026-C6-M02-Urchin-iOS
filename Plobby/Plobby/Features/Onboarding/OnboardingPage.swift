//
//  OnboardingPage.swift
//  Plobby
//
//  Created by 이은지 on 10/30/26.
//

enum OnboardingPage: Int, CaseIterable {

    case goal, record, map, collection

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

    func title(isCardFlipped: Bool) -> String {
        if self == .collection, isCardFlipped {
            return "쓰레기를 주워 바다 생물을 도와요"
        }

        return title
    }

    func description(isCardFlipped: Bool) -> String {
        if self == .collection, isCardFlipped {
            return "같은 버튼을 다시 누르면 앞면으로 돌아가요"
        }

        return description
    }

    private var title: String {
        switch self {
        case .goal: "함께 바다를 지켜요"
        case .record: "수거한 쓰레기를 기록해요"
        case .map: "지도에서 기록을 찾아봐요"
        case .collection: "내가 치운 쓰레기, 컬렉션에 종류별로 모아요"
        }
    }

    private var description: String {
        switch self {
        case .goal: "해변에서 쓰레기를 줍는 건 플로깅,\n바닷속에서 줍는 건 플로빙이에요"
        case .record: "내가 기록한 개수만큼 공통 목표에 가까워져요"
        case .map: "누가 어디서 어떤 쓰레기를 주웠는지 볼 수 있어요"
        case .collection: "오른쪽 위 버튼을 누르면 내가 도운 바다 생물도 보여요"
        }
    }

    var showsActivityTabs: Bool {
        switch self {
        case .goal, .record: true
        case .map, .collection: false
        }
    }
}
