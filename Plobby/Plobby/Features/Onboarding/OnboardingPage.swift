//
//  OnboardingPage.swift
//  Plobby
//
//  Created by 이은지 on 10/30/26.
//

enum OnboardingPage: Int, CaseIterable {

    case record, goal, map, collection

    var number: Int {
        rawValue + 1
    }

    var next: OnboardingPage? {
        OnboardingPage(rawValue: rawValue + 1)
    }

    var isLast: Bool {
        next == nil
    }
}

extension OnboardingPage {

    var title: String {
        switch self {
        case .record: "바다를 위한 행동,\n간편하게 기록해요"
        case .goal: "깨끗한 바다,\n우리가 함께 만들어가요"
        case .map: "우리가 남긴 발자취,\n지도에서 찾아봐요"
        case .collection: "내가 주운 쓰레기,\n카드에 모아봐요"
        }
    }

    var description: String {
        switch self {
        case .record: "해변과 바닷속에서 주운 쓰레기의 종류와 개수,\n사진과 장소를 한 번에 남길 수 있어요"
        case .goal: "내가 주운 쓰레기가 모두의 기록에 더해져요.\n홈에서 우리가 달성 중인 목표를 확인해 보세요"
        case .map: "해변을 검색해 의미 있는\n정화 활동을 한눈에 확인해 보세요"
        case .collection: "카드 앞면에선 그동안 모은 쓰레기 개수를,\n뒷면에선 바다 생물에게 준 도움을 확인할 수 있어요"
        }
    }

    var showsActivityTabs: Bool {
        switch self {
        case .record, .goal: true
        case .map, .collection: false
        }
    }
}
