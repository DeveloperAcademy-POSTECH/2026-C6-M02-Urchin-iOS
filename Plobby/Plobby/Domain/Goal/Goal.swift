//
//  Goal.swift
//  Plobby
//
//  Created by dlsundn on 11/9/26.
//

import Foundation

nonisolated struct Goal: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let targetCount: Int
    let startsAt: Date
    let endsAt: Date
    let achievedAt: Date?
    let collectedCount: Int
    let ploggingCollectedCount: Int
    let plobbingCollectedCount: Int
    let participantCount: Int
    let ploggingParticipantCount: Int
    let plobbingParticipantCount: Int
}

// MARK: - Status

nonisolated extension Goal {
    
    enum Status: Equatable, Sendable {
        case inProgress
        case achieved
        case ended
    }
    
    func status(at now: Date) -> Status {
        guard achievedAt == nil else { return .achieved }
        
        return now < endsAt ? .inProgress : .ended
    }
    
    func dDay(at now: Date) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        return calendar.dateComponents([.day], from: today, to: lastDay).day ?? 0
    }
    
    var lastDay: Date {
        Calendar.current.startOfDay(for: endsAt.addingTimeInterval(-1))
    }
    
    var progress: Double {
        guard targetCount > 0 else { return 0 }
        
        return min(Double(collectedCount) / Double(targetCount), 1)
    }
    
    func homeStatus(at now: Date) -> HomeGoalStatus {
        if achievedAt == nil, now < startsAt {
            let calendar = Calendar.current
            let days = calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: now),
                to: calendar.startOfDay(for: startsAt)
            ).day ?? 0
            return .upcoming(daysUntilStart: max(days, 0))
        }

        return switch status(at: now) {
        case .inProgress: .inProgress(remainingDays: max(dDay(at: now), 0))
        case .achieved: .achieved
        case .ended: .ended
        }
    }
}

// MARK: - 홈 목표

nonisolated extension Goal {

    /// 홈에 보여줄 목표예요.
    /// 1. 가장 최근에 끝난(달성·기간 종료) 목표. 단, "다음 목표 보기"로 넘긴 목표면 건너뛰어요.
    /// 2. 진행 중(미달성·기간 안)인 목표
    /// 3. 아직 시작하지 않은 다음 목표
    /// 4. 다음 목표가 없으면 넘긴 목표라도 가장 최근에 끝난 목표
    /// "다음 목표 보기"로 넘긴 목표를 기억하는 값이에요.
    /// 달성(또는 종료) 시각까지 넣어서, 같은 목표가 다시 달성되면 새로 축하해요.
    var dismissalKey: String {
        "\(id.uuidString)|\(Int((achievedAt ?? endsAt).timeIntervalSince1970))"
    }

    static func homeGoal(
        in goals: [Goal],
        upcoming: Goal? = nil,
        skipping skippedKeys: Set<String> = [],
        at now: Date
    ) -> Goal? {
        let started = goals
            .filter { $0.startsAt <= now }
            .sorted { $0.startsAt > $1.startsAt }

        let inProgress = started.first { $0.status(at: now) == .inProgress }
        let latestFinished = started.first { $0.status(at: now) != .inProgress }

        // 달성 축하는 "다음 목표 보기"를 누를 때까지 보여줘요. 다음 목표가 이미 시작했어도 끝난 목표가 먼저예요.
        if let latestFinished, !skippedKeys.contains(latestFinished.dismissalKey) {
            return latestFinished
        }
        return inProgress ?? upcoming ?? latestFinished
    }
}

// MARK: - MainActor

@MainActor extension Goal {
    
    var periodText: String {
        "\(startsAt.homeMonthDayText) ~ \(lastDay.homeMonthDayText)"
    }
}

// MARK: - RecordType

nonisolated extension Goal {
    
    func collectedCount(for recordType: RecordType) -> Int {
        switch recordType {
        case .plogging: ploggingCollectedCount
        case .plobbing: plobbingCollectedCount
        }
    }
    
    func participantCount(for recordType: RecordType) -> Int {
        switch recordType {
        case .plogging: ploggingParticipantCount
        case .plobbing: plobbingParticipantCount
        }
    }
}
