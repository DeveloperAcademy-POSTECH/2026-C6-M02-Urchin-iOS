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
    let recordID: UUID
    let beachName: String?
    let recordType: RecordType?
    var isRead: Bool
    let isRecordDeleted: Bool
    let createdAt: Date
}

extension AppNotification {

    enum Kind: Equatable {
        /// 같은 기록에 받은 좋아요를 묶은 알림. `likerNickname`은 가장 최근에 누른 사람이에요.
        case like(likerNickname: String?, othersCount: Int)
        /// 관심 해변에 새 기록이 올라온 알림
        case newRecordAtFavoriteBeach(authorNickname: String?)
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
        }
    }

    var subtitle: String {
        switch kind {
        case .like:
            return [beachName, recordType?.name]
                .compactMap { $0 }
                .joined(separator: " ")

        case let .newRecordAtFavoriteBeach(authorNickname):
            let author = "\(authorNickname ?? "누군가")님"
            let recordName = recordType.map { "\($0.name) 기록" } ?? "기록"
            return "\(author)이 남긴 \(recordName)"
        }
    }
}
