//
//  AppNotification.swift
//  Plobby
//
//  Created by dlsundn on 11/3/26.
//

import Foundation

struct AppNotification: Identifiable, Equatable {
    let id: UUID
    let kind: Kind
    let recordID: UUID?
    let beachName: String?
    let recordType: RecordType?
    var isRead: Bool
    let isRecordDeleted: Bool
    let goalID: UUID?
    let goalTitle: String?
    let recordStartedAt: Date?
    let createdAt: Date
}

extension AppNotification {

    enum Kind: Equatable {
        case like(likerNickname: String?, othersCount: Int)
        case newRecordAtFavoriteBeach(authorNickname: String?)
        case reportRemoved
        case goalAchieved
    }

    var canOpenRecord: Bool {
        guard recordID != nil, !isRecordDeleted else { return false }

        switch kind {
        case .like, .newRecordAtFavoriteBeach: return true
        case .reportRemoved, .goalAchieved: return false
        }
    }

    var canReturnHome: Bool {
        kind == .goalAchieved
    }
}

// MARK: - Text

extension AppNotification {

    var title: String {
        switch kind {
        case let .like(likerNickname, othersCount):
            let liker = "\(likerNickname ?? "누군가")님"
            return othersCount > 0
                ? "\(liker) 외 \(othersCount)명이 내 기록을 좋아해요"
                : "\(liker)이 내 기록을 좋아해요"

        case .newRecordAtFavoriteBeach:
            return "\(beachName ?? "관심 해변")에 새 기록이 올라왔어요"

        case .reportRemoved:
            return "작성한 활동 기록이 신고를 받아 삭제됐어요"

        case .goalAchieved:
            return "공동 목표를 달성했어요!"
        }
    }

    var subtitle: String {
        switch kind {
        case .like:
            return recordName

        case .reportRemoved:
            guard let recordStartedAt else { return recordName }

            return "\(recordName) · \(recordStartedAt.formatted(Self.recordDateStyle))"

        case let .newRecordAtFavoriteBeach(authorNickname):
            let author = "\(authorNickname ?? "누군가")님"
            let recordName = recordType.map { "\($0.name) 기록" } ?? "기록"
            return "\(author)이 남긴 \(recordName)"

        case .goalAchieved:
            return goalTitle ?? ""
        }
    }

    private var recordName: String {
        [beachName, recordType?.name]
            .compactMap { $0 }
            .joined(separator: " ")
    }

    private static let recordDateStyle = Date.VerbatimFormatStyle(
        format: "\(year: .defaultDigits)년 \(month: .defaultDigits)월 \(day: .defaultDigits)일",
        timeZone: .current,
        calendar: .current
    )
}
