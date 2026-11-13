//
//  RecordClient.swift
//  Plobby
//
//  Created by 더스틴 on 11/2/26.
//

import Foundation

import Dependencies
import Supabase

nonisolated struct RecordClient {
    var fetchRecord: @Sendable (_ recordID: UUID) async throws -> RecordDetail
    var fetchRecords: @Sendable (_ offset: Int, _ limit: Int) async throws -> [RecordSummary]
    var fetchUserRecords: @Sendable (_ userID: UUID) async throws -> [RecordSummary]
    var submitRecord: @Sendable (_ record: NewRecord) async throws -> Void
    var updateRecord: @Sendable (_ record: UpdatedRecord) async throws -> Void
    var like: @Sendable (_ recordID: UUID) async throws -> Void
    var unlike: @Sendable (_ recordID: UUID) async throws -> Void
    var removeRecord: @Sendable (_ recordID: UUID) async throws -> Void
    var reportRecord: @Sendable (_ recordID: UUID, _ reason: ReportReason, _ detail: String?) async throws -> Void
    var fetchTrashCounts: @Sendable (_ userID: UUID) async throws -> [TrashCategory: Int]
}

nonisolated extension RecordClient: DependencyKey {
    static let liveValue: RecordClient = {
        return .init(
            fetchRecord: { recordID in
                @Dependency(\.supabaseClient) var supabaseClient
                
                let userID = try await supabaseClient.currentUserIDIfSignedIn()
                
                var query = supabaseClient
                    .from("records")
                    .select(RecordDetailResponseDTO.selectQuery)
                    .eq("id", value: recordID)
                    .is("deleted_at", value: nil)
                
                if let userID {
                    query = query.eq("my_like.user_id", value: userID)
                }
                
                let responseDTO: RecordDetailResponseDTO = try await query
                    .single()
                    .execute()
                    .value
                
                return try responseDTO.toDomain(
                    currentUserID: userID,
                    photoURL: supabaseClient.recordPhotoURL,
                    profileImageURL: supabaseClient.profileImageURL
                )
            }, fetchRecords: { offset, limit in
                @Dependency(\.supabaseClient) var supabaseClient
                
                let userID = try await supabaseClient.currentUserIDIfSignedIn()
                let hiddenRecords = try await supabaseClient.hiddenRecords()

                var query = supabaseClient
                    .from("records")
                    .select(RecordSummaryResponseDTO.selectQuery)
                    .is("deleted_at", value: nil)
                    .excluding(hiddenRecords)

                if let userID {
                    query = query.eq("my_like.user_id", value: userID)
                }

                let responseDTOs: [RecordSummaryResponseDTO] = try await query
                    .order("created_at", ascending: false)
                    .range(from: offset, to: offset + limit - 1)
                    .execute()
                    .value

                return responseDTOs.compactMap {
                    $0.toDomain(
                        currentUserID: userID,
                        photoURL: supabaseClient.recordPhotoURL,
                        profileImageURL: supabaseClient.profileImageURL
                    )
                }
            }, fetchUserRecords: { userID in
                @Dependency(\.supabaseClient) var supabaseClient

                async let currentUserIDTask = supabaseClient.currentUserIDIfSignedIn()
                async let hiddenRecordsTask = supabaseClient.hiddenRecords()
                let (currentUserID, hiddenRecords) = try await (currentUserIDTask, hiddenRecordsTask)

                var query = supabaseClient
                    .from("records")
                    .select(RecordSummaryResponseDTO.selectQuery)
                    .eq("user_id", value: userID)
                    .is("deleted_at", value: nil)
                    .excluding(hiddenRecords)

                if let currentUserID {
                    query = query.eq("my_like.user_id", value: currentUserID)
                }

                let responseDTOs: [RecordSummaryResponseDTO] = try await query
                    .order("created_at", ascending: false)
                    .execute()
                    .value

                return responseDTOs.compactMap {
                    $0.toDomain(
                        currentUserID: currentUserID,
                        photoURL: supabaseClient.recordPhotoURL,
                        profileImageURL: supabaseClient.profileImageURL
                    )
                }
            }, submitRecord: { record in
                @Dependency(\.supabaseClient) var supabaseClient
                
                let photoKeys = try await supabaseClient.uploadRecordPhotos(record.photos, recordID: record.id)
                let requestDTO = CreateRecordRequestDTO(from: record, photoKeys: photoKeys)
                try await supabaseClient
                    .rpc("create_record", params: requestDTO)
                    .execute()
                    .value
            }, updateRecord: { record in
                @Dependency(\.supabaseClient) var supabaseClient
                
                let photoKeys = try await supabaseClient.uploadRecordPhotos(record.photos, recordID: record.id)
                let requestDTO = UpdateRecordRequestDTO(from: record, photoKeys: photoKeys)
                try await supabaseClient
                    .rpc("update_record", params: requestDTO)
                    .execute()
            }, like: { recordID in
                @Dependency(\.supabaseClient) var supabaseClient
                
                let userID = try await supabaseClient.currentUserID()
                
                try await supabaseClient
                    .from("record_likes")
                    .insert(RecordLikeInsertRequestDTO(recordID: recordID, userID: userID))
                    .execute()
            }, unlike: { recordID in
                @Dependency(\.supabaseClient) var supabaseClient
                
                let uid = try await supabaseClient.currentUserID()
                
                try await supabaseClient
                    .from("record_likes")
                    .delete()
                    .eq("record_id", value: recordID)
                    .eq("user_id", value: uid)
                    .execute()
            }, removeRecord: { recordID in
                @Dependency(\.supabaseClient) var supabaseClient
                
                let uid = try await supabaseClient.currentUserID()
                
                try await supabaseClient
                    .from("records")
                    .update(DeletedAtUpdateRequestDTO(deletedAt: .now))
                    .eq("id", value: recordID)
                    .eq("user_id", value: uid)
                    .is("deleted_at", value: nil)
                    .execute()
            }, reportRecord: { recordID, reason, detail in
                @Dependency(\.supabaseClient) var supabaseClient
                
                let uid = try await supabaseClient.currentUserID()
                
                try await supabaseClient
                    .from("record_reports")
                    .insert(RecordReportInsertRequestDTO(
                        recordID: recordID,
                        reporterID: uid,
                        reason: reason.rawValue,
                        reasonDetail: detail
                    ))
                    .execute()
            }, fetchTrashCounts: { userID in
                @Dependency(\.supabaseClient) var supabaseClient

                let responseDTOs: [UserTrashSummaryResponseDTO] = try await supabaseClient
                    .from("user_trash_summary")
                    .select("trash_code, collected_count")
                    .eq("user_id", value: userID)
                    .execute()
                    .value

                return responseDTOs.reduce(into: [:]) { counts, responseDTO in
                    guard let category = TrashCategory(code: responseDTO.trashCode) else { return }

                    counts[category] = responseDTO.collectedCount
                }
            }
        )
    }()
}

// MARK: - Storage

nonisolated enum StorageBucket {
    
    static let image = "Plobby Image Bucket"
    static let profile = "Plobby Profile Bucket"
}

private nonisolated extension SupabaseClient {
    
    /// 새 사진만 올리고, 기존 사진은 storage key를 그대로 써요. 반환하는 key는 사진 순서와 같아요.
    /// 기존 사진과 경로가 겹치지 않도록 새 사진은 매번 새 파일 이름으로 올려요.
    func uploadRecordPhotos(_ photos: [RecordPhotoUpload], recordID: UUID) async throws -> [String] {
        let userID = try await currentUserID()
        let folder = "\(userID.uuidString.lowercased())/\(recordID.uuidString.lowercased())"
        
        var photoKeys: [String] = []
        for photo in photos {
            switch photo {
            case let .new(data):
                let path = "\(folder)/\(UUID().uuidString.lowercased()).jpg"
                
                try await storage
                    .from(StorageBucket.image)
                    .upload(path, data: data, options: FileOptions(contentType: "image/jpeg"))
                
                photoKeys.append(path)
                
            case let .existing(storageKey):
                photoKeys.append(storageKey)
            }
        }
        return photoKeys
    }
}
