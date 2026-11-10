//
//  HomeMock.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import Foundation

// TODO: Supabase 목표 테이블·뷰와 Client가 준비되면 실제 데이터로 교체
/// 홈 화면 개편용 임시 데이터예요.
enum HomeMock {

    /// 지금 진행 중인 목표와 장면 데이터예요.
    static func board(for recordType: RecordType, now: Date, calendar: Calendar) -> HomeGoalBoard {
        let startsAt = day(-6, from: now, calendar: calendar)
        let goal = HomeGoal(
            id: goalID(recordType),
            recordType: recordType,
            title: "해양 쓰레기 줍기",
            targetCount: 200,
            startsAt: startsAt,
            endsAt: day(7, from: now, calendar: calendar),
            collectedCount: 74,
            participantCount: recordType == .plogging ? 18 : 30
        )
        // 기록이 있는 날만 내려와요. 마지막 날이 오늘이에요.
        let dailyCounts: [(dayOffset: Int, collected: Int, participants: Int)] = recordType == .plogging
            ? [(0, 15, 6), (2, 10, 3), (4, 12, 5), (6, 12, 4)]
            : [(0, 5, 3), (2, 20, 6), (4, 18, 4), (6, 31, 6)]

        return HomeGoalBoard(
            goal: goal,
            days: dailyCounts.map { count in
                HomeGoalDailyProgress(
                    day: day(count.dayOffset, from: startsAt, calendar: calendar),
                    collectedCount: count.collected,
                    participantCount: count.participants
                )
            },
            trashCounts: recordType == .plogging ? ploggingTrash : plobbingTrash,
            participants: participants(for: recordType),
            records: records(recordType: recordType, startsAt: startsAt, calendar: calendar)
        )
    }

    /// 공동 목표 목록의 지난 목표예요.
    static func pastGoals(for recordType: RecordType, now: Date, calendar: Calendar) -> [HomeGoal] {
        [
            HomeGoal(
                id: UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!,
                recordType: recordType,
                title: "가을 해변 정화",
                targetCount: 160,
                startsAt: day(-20, from: now, calendar: calendar),
                endsAt: day(-7, from: now, calendar: calendar),
                collectedCount: 160,
                participantCount: 24
            ),
            HomeGoal(
                id: UUID(uuidString: "00000000-0000-0000-0000-0000000000A2")!,
                recordType: recordType,
                title: "항구 주변 쓰레기 줍기",
                targetCount: 120,
                startsAt: day(-34, from: now, calendar: calendar),
                endsAt: day(-21, from: now, calendar: calendar),
                collectedCount: 96,
                participantCount: 16
            )
        ]
    }

    /// 수거 기록 화면에 보여줄 기록이에요.
    static func records(for goal: HomeGoal, calendar: Calendar) -> [HomeGoalRecord] {
        records(recordType: goal.recordType, startsAt: goal.startsAt, calendar: calendar)
    }
}

// MARK: - Data

private extension HomeMock {

    static func goalID(_ recordType: RecordType) -> UUID {
        switch recordType {
        case .plogging: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        case .plobbing: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        }
    }

    static let ploggingTrash: [HomeGoalTrashCount] = [
        HomeGoalTrashCount(category: .plastic, count: 14),
        HomeGoalTrashCount(category: .can, count: 10),
        HomeGoalTrashCount(category: .glass, count: 5),
        HomeGoalTrashCount(category: .paper, count: 4),
        HomeGoalTrashCount(category: .etc, count: 6)
    ]

    static let plobbingTrash: [HomeGoalTrashCount] = [
        HomeGoalTrashCount(category: .glass, count: 5),
        HomeGoalTrashCount(category: .plastic, count: 14),
        HomeGoalTrashCount(category: .metal, count: 3),
        HomeGoalTrashCount(category: .wood, count: 3),
        HomeGoalTrashCount(category: .fishingGear, count: 9),
        HomeGoalTrashCount(category: .clothing, count: 2),
        HomeGoalTrashCount(category: .styrofoam, count: 5),
        HomeGoalTrashCount(category: .can, count: 10),
        HomeGoalTrashCount(category: .paper, count: 4),
        HomeGoalTrashCount(category: .rubber, count: 2),
        HomeGoalTrashCount(category: .etc, count: 7)
    ]

    /// 활동별로 참여한 사람과 모은 개수예요. 차단한 사용자도 한 명 섞여 있어요.
    static func participants(for recordType: RecordType) -> [HomeGoalParticipant] {
        let rows: [(nickname: String, count: Int, isBlocked: Bool)] = recordType == .plobbing
            ? [
                ("오키오키만만수", 10, false), ("해녀와바다", 8, false), ("바다가허락하는날을", 6, false),
                ("포항물회", 5, true), ("여울", 3, false), ("해솔", 2, false),
                ("바다별", 2, false), ("푸른섬", 1, false), ("윤슬", 1, false), ("갈매기", 1, false)
            ]
            : [
                ("파랑새", 7, false), ("가람", 6, false), ("산호빛", 5, false), ("모래알", 4, true),
                ("보리", 4, false), ("솔바람", 3, false), ("조약돌", 2, false), ("지나", 1, false)
            ]
        let base = recordType == .plobbing ? 100 : 150
        return rows.enumerated().map { offset, row in
            HomeGoalParticipant(
                id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", base + offset))!,
                nickname: row.nickname,
                profileImageURL: nil,
                collectedCount: row.count,
                isBlocked: row.isBlocked
            )
        }
    }

    static func records(recordType: RecordType, startsAt: Date, calendar: Calendar) -> [HomeGoalRecord] {
        let rows: [(beach: String, nickname: String, dayOffset: Int, count: Int)] = [
            ("광안리 해수욕장", "지나", 3, 32),
            ("안목 해수욕장", "산호빛", 2, 24),
            ("협재 해수욕장", "가람", 0, 18)
        ]
        return rows.enumerated().map { offset, row in
            HomeGoalRecord(
                id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", 200 + offset))!,
                recordType: recordType,
                beachName: row.beach,
                nickname: row.nickname,
                createdAt: day(row.dayOffset, from: startsAt, calendar: calendar),
                collectedCount: row.count,
                thumbnailURL: nil
            )
        }
    }

    static func day(_ offset: Int, from date: Date, calendar: Calendar) -> Date {
        calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: date)) ?? date
    }
}
