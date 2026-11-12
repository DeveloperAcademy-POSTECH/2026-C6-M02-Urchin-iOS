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
    /// 기록과 상관없는 알림(목표 달성 등)은 비어 있어요.
    let recordID: UUID?
    let beachName: String?
    let recordType: RecordType?
    var isRead: Bool
    let isRecordDeleted: Bool
    /// 목표 달성 알림이 가리키는 목표예요.
    let goalID: UUID?
    let createdAt: Date
}

extension AppNotification {

    enum Kind: Equatable {
        /// 같은 기록에 받은 좋아요를 묶은 알림. `likerNickname`은 가장 최근에 누른 사람이에요.
        case like(likerNickname: String?, othersCount: Int)
        /// 관심 해변에 새 기록이 올라온 알림
        case newRecordAtFavoriteBeach(authorNickname: String?)
        /// 신고가 접수돼 관리자가 내 기록을 삭제한 알림. 보낸 사람이 없어요.
        case reportRemoved
        /// 내가 참여한 공동 목표를 달성한 알림. 보낸 사람이 없어요.
        case goalAchieved
    }

    /// 눌렀을 때 기록 상세로 갈 수 있는지예요. 삭제된 기록이나 기록이 없는 알림은 이동하지 않아요.
    var canOpenRecord: Bool {
        guard recordID != nil, !isRecordDeleted else { return false }

        switch kind {
        case .like, .newRecordAtFavoriteBeach: return true
        case .reportRemoved, .goalAchieved: return false
        }
    }

    /// 눌렀을 때 홈으로 돌아가서 달성한 공동 목표를 보여주는 알림이에요.
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
            return "신고 접수로 회원님의 기록이 삭제되었어요"

        case .goalAchieved:
            return "함께한 공동 목표를 달성했어요"
        }
    }

    var subtitle: String {
        switch kind {
        case .like, .reportRemoved:
            return [beachName, recordType?.name]
                .compactMap { $0 }
                .joined(separator: " ")

        case let .newRecordAtFavoriteBeach(authorNickname):
            let author = "\(authorNickname ?? "누군가")님"
            let recordName = recordType.map { "\($0.name) 기록" } ?? "기록"
            return "\(author)이 남긴 \(recordName)"

        case .goalAchieved:
            return "모두가 모은 쓰레기를 확인해 보세요"
        }
    }
}
