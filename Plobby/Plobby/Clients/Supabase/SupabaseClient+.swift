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
