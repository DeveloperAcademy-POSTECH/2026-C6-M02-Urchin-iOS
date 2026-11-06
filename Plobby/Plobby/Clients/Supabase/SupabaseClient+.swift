//
//  SupabaseClient+.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import Foundation

import Supabase

extension SupabaseClient {
    
    func currentUserID() async throws -> UUID {
        try await auth.session.user.id
    }

    /// 로그인하지 않은 비회원이면 nil이에요. 네트워크 오류처럼 다른 에러는 그대로 던져요.
    func currentUserIDIfSignedIn() async throws -> UUID? {
        do {
            return try await currentUserID()
        } catch AuthError.sessionMissing {
            return nil
        }
    }

    /// 기록 사진의 storage key로 공개 URL을 만들어요.
    nonisolated func recordPhotoURL(_ storageKey: String) -> URL? {
        try? storage.from(StorageBucket.image).getPublicURL(path: storageKey)
    }

    /// 프로필 사진의 storage key로 공개 URL을 만들어요.
    nonisolated func profileImageURL(_ storageKey: String) -> URL? {
        try? storage.from(StorageBucket.profile).getPublicURL(path: storageKey)
    }

    /// 프로필 사진을 Storage에 올리고 저장 경로(key)를 돌려줘요.
    /// 파일 이름에 시각을 넣어, 사진을 바꿨을 때 이전 사진이 캐시로 보이지 않게 해요.
    func uploadProfileImage(_ data: Data, userID: UUID) async throws -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let path = "\(userID.uuidString.lowercased())/profile-\(timestamp).jpg"

        try await storage
            .from("Plobby Profile Bucket")
            .upload(
                path,
                data: data,
                options: FileOptions(contentType: "image/jpeg", upsert: true)
            )

        return path
    }

    /// Storage에서 프로필 사진 파일을 지워요.
    func removeProfileImage(_ key: String) async throws {
        _ = try await storage
            .from("Plobby Profile Bucket")
            .remove(paths: [key])
    }
}

// MARK: - 나에게 숨기는 기록

/// 로그인한 사용자에게만 보이지 않게 할 기록. 신고한 기록과 차단한 사용자의 기록이에요.
nonisolated struct HiddenRecords: Sendable {

    var recordIDs: [UUID] = []
    var userIDs: [UUID] = []
}

extension SupabaseClient {

    /// 둘러보기 중이면 숨길 기록이 없어요.
    func hiddenRecords() async throws -> HiddenRecords {
        guard let userID = try? await currentUserID() else { return HiddenRecords() }

        async let reported: [ReportedRecordResponse] = from("record_reports")
            .select("record_id")
            .eq("reporter_id", value: userID)
            .execute()
            .value

        async let blocked: [BlockedUserIDResponse] = from("user_blocks")
            .select("blocked_id")
            .eq("blocker_id", value: userID)
            .execute()
            .value

        return try await HiddenRecords(
            recordIDs: reported.map(\.recordID),
            userIDs: blocked.map(\.blockedID)
        )
    }
}

nonisolated extension PostgrestFilterBuilder {

    /// 숨길 기록은 그 사용자에게만 빼요. 다른 사용자에게는 그대로 보여요.
    func excluding(_ hidden: HiddenRecords) -> PostgrestFilterBuilder {
        var query = self

        if !hidden.recordIDs.isEmpty {
            query = query.notIn("id", values: hidden.recordIDs.map(\.uuidString))
        }
        if !hidden.userIDs.isEmpty {
            query = query.notIn("user_id", values: hidden.userIDs.map(\.uuidString))
        }
        return query
    }
}

private nonisolated struct ReportedRecordResponse: Decodable, Sendable {

    let recordID: UUID

    enum CodingKeys: String, CodingKey {
        case recordID = "record_id"
    }
}

private nonisolated struct BlockedUserIDResponse: Decodable, Sendable {

    let blockedID: UUID

    enum CodingKeys: String, CodingKey {
        case blockedID = "blocked_id"
    }
}
