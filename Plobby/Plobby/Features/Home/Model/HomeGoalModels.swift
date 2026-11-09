//
//  HomeGoalModels.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import Foundation

// 홈 화면에서만 쓰는 공동 목표 관련 화면 모델이에요.
// 실제 도메인 모델과 DTO, Client가 준비되면 이 타입들을 교체해요. 지금은 HomeMock 데이터로 채워요.

/// `goals` 테이블과 `goal_progress` 뷰를 합친 목표 하나예요.
struct HomeGoal: Identifiable, Equatable, Sendable {
    let id: UUID
    let recordType: RecordType
    let title: String
    let targetCount: Int
    let startsAt: Date
    let endsAt: Date
    /// `goal_progress.collected_count`
    let collectedCount: Int
    /// `goal_progress.participant_count`
    let participantCount: Int

    var progress: Double {
        guard targetCount > 0 else { return 0 }
        return min(Double(collectedCount) / Double(targetCount), 1)
    }

    /// 서버에서 받은 끝 시각과 개수를 오늘 날짜와 비교해 앱에서 정해요.
    func status(now: Date, calendar: Calendar) -> HomeGoalStatus {
        if collectedCount >= targetCount {
            return .achieved
        }
        if now > endsAt {
            return .ended
        }
        let today = calendar.startOfDay(for: now)
        let lastDay = calendar.startOfDay(for: endsAt)
        let remainingDays = calendar.dateComponents([.day], from: today, to: lastDay).day ?? 0
        return .inProgress(remainingDays: max(remainingDays, 0))
    }
}

enum HomeGoalStatus: Equatable, Sendable {
    case inProgress(remainingDays: Int)
    case achieved
    case ended

    var isFinished: Bool {
        remainingDays == nil
    }

    var remainingDays: Int? {
        if case let .inProgress(remainingDays) = self { return remainingDays }
        return nil
    }

    /// 목표 상태 칩에 쓰는 문구예요. (D-7, D-Day, 목표 달성, 기간 종료)
    var chipText: String {
        switch self {
        case let .inProgress(remainingDays): remainingDays == 0 ? "D-Day" : "D-\(remainingDays)"
        case .achieved: "목표 달성"
        case .ended: "기간 종료"
        }
    }
}

/// `goal_daily_progress` 뷰의 한 줄이에요. 장면은 날짜 단위로 넘어가요.
struct HomeGoalDailyProgress: Identifiable, Equatable, Sendable {
    let day: Date
    /// 그날 모은 개수
    let collectedCount: Int
    /// 그날 참여자 수 (장면에는 최대 6명까지 보여줘요)
    let participantCount: Int

    var id: Date { day }
}

/// 쓰레기 종류별 합계 뷰의 한 줄이에요. 배·수거대에 모은 쓰레기 시트에 써요.
struct HomeGoalTrashCount: Identifiable, Equatable, Sendable {
    let category: TrashCategory
    let count: Int

    var id: TrashCategory { category }
}

/// 목표 기간 동안 해당 활동(플로깅/플로빙)을 함께한 사람이에요.
struct HomeGoalParticipant: Identifiable, Equatable, Sendable {
    let id: UUID
    let nickname: String
    let profileImageURL: URL?
    /// 목표 기간 동안 모은 개수
    let collectedCount: Int
    /// 내가 차단한 사용자면 닉네임과 프로필을 가려요.
    let isBlocked: Bool
}

/// 수거량 순으로 매긴 순위예요. 같은 수거량은 같은 순위예요. (1, 2, 2, 4 …)
struct HomeRankedParticipant: Identifiable, Equatable, Sendable {
    let rank: Int
    let participant: HomeGoalParticipant

    var id: HomeGoalParticipant.ID { participant.id }
}

/// 목표 기간 안에 올라온 기록이에요. 수거 기록 화면에 써요.
struct HomeGoalRecord: Identifiable, Equatable, Sendable {
    let id: UUID
    let recordType: RecordType
    let beachName: String
    let nickname: String
    let createdAt: Date
    let collectedCount: Int
    let thumbnailURL: URL?

    var title: String {
        "\(beachName) \(recordType.name) 기록"
    }
}

/// 홈 장면 하나(플로깅 또는 플로빙)에 필요한 데이터를 묶었어요.
struct HomeGoalBoard: Equatable, Sendable {
    let goal: HomeGoal
    let days: [HomeGoalDailyProgress]
    let trashCounts: [HomeGoalTrashCount]
    let participants: [HomeGoalParticipant]
    let records: [HomeGoalRecord]

    var totalTrashCount: Int {
        trashCounts.reduce(0) { $0 + $1.count }
    }

    /// 이 활동에 참여한 사람 수예요.
    var participantCount: Int {
        participants.count
    }

    /// 이 활동에서 함께 모은 개수예요.
    var participantCollectedCount: Int {
        participants.reduce(0) { $0 + $1.collectedCount }
    }

    var rankedParticipants: [HomeRankedParticipant] {
        let sorted = participants.sorted { $0.collectedCount > $1.collectedCount }
        return sorted.map { participant in
            let rank = (sorted.firstIndex { $0.collectedCount == participant.collectedCount } ?? 0) + 1
            return HomeRankedParticipant(rank: rank, participant: participant)
        }
    }
}
