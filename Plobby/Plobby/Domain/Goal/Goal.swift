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
        min(Double(collectedCount) / Double(targetCount), 1)
    }
    
    func homeStatus(at now: Date) -> HomeGoalStatus {
        switch status(at: now) {
        case .inProgress: .inProgress(remainingDays: max(dDay(at: now), 0))
        case .achieved: .achieved
        case .ended: .ended
        }
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
