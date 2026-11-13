//
//  BeachSummary.swift
//  Plobby
//
//  Created by 더스틴 on 11/6/26.
//

import Foundation

//TODO: 추후 뷰 생성 시 대체하기
nonisolated struct BeachSummary: Equatable, Sendable {

    let recordCount: Int
    let participantCount: Int
    let totalTrashCount: Int
    let photoURLs: [URL]
    let guardians: [Guardian]
}

extension BeachSummary {

    nonisolated struct Guardian: Equatable, Identifiable, Sendable {

        let id: UUID
        let nickname: String
        let profileImageURL: URL?
        /// 내가 차단한 회원이에요. 빼지 않고 "차단한 회원"으로 보여줘요.
        var isBlocked = false
    }
}
