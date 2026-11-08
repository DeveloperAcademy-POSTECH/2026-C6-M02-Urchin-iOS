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
    
    /// 달성 시각이 있으면 목표 달성, 없으면 끝 시각과 비교
    func status(at now: Date) -> Status {
        guard achievedAt == nil else { return .achieved }
        
        return now < endsAt ? .inProgress : .ended
    }
    
    /// 마지막 날 까지 남은 일수, 마지막 날이면 0
    func dDay(at now: Date) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        return calendar.dateComponents([.day], from: today, to: lastDay).day ?? 0
    }
    
    /// 화면에 보여주는 마지막 날, 끝 시각은 기간에 포함되지 않아 1초 전 날짜를 사용
    var lastDay: Date {
        Calendar.current.startOfDay(for: endsAt.addingTimeInterval(-1))
    }
    
    /// 진행 바 비율
    var progress: Double {
        min(Double(collectedCount) / Double(targetCount), 1)
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
