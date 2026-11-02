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
    var submitRecord: @Sendable (_ record: NewRecord) async throws -> Void
    var updateRecord: @Sendable (_ record: UpdatedRecord) async throws -> Void
    var like: @Sendable (_ recordID: UUID) async throws -> Void
    var unlike: @Sendable (_ recordID: UUID) async throws -> Void
    var removeRecord: @Sendable (_ recordID: UUID) async throws -> Void
    var reportRecord: @Sendable (_ report: RecordReport) async throws -> Void
}

nonisolated extension RecordClient: DependencyKey {
    static let liveValue: RecordClient = {
        return .init(
            fetchRecord: { recordID in
                @Dependency(\.supabaseClient) var supabaseClient
                
                let responseDTO: RecordDetailResponseDTO = try await supabaseClient
                    .from("records")
                    .select(RecordDetailResponseDTO.selectQuery)
                    .eq("id", value: recordID)
                    .is("deleted_at", value: nil)
                    .single()
                    .execute()
                    .value

                return try responseDTO.toDomain()
            }, fetchRecords: { offset, limit in
                @Dependency(\.supabaseClient) var supabaseClient
                
                let userID = try await supabaseClient.currentUserID()

                let responseDTOs: [RecordSummaryResponseDTO] = try await supabaseClient
                    .from("records")
                    .select(RecordSummaryResponseDTO.selectQuery)
                    .is("deleted_at", value: nil)
                    .eq("my_like.user_id", value: userID)
                    .order("created_at", ascending: false)
                    .range(from: offset, to: offset + limit - 1)
                    .execute()
                    .value

                return responseDTOs.compactMap { $0.toDomain() }
            }, submitRecord: { record in
                @Dependency(\.supabaseClient) var supabaseClient
                
                let requestDTO = CreateRecordRequestDTO(from: record)
                try await supabaseClient
                    .rpc("create_record", params: requestDTO)
                    .execute()
                    .value
            }, updateRecord: { record in
                @Dependency(\.supabaseClient) var supabaseClient
                
                let requestDTO = UpdateRecordRequestDTO(from: record)
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
            }, reportRecord: { report in
                @Dependency(\.supabaseClient) var supabaseClient
                
                let uid = try await supabaseClient.currentUserID()
                
                try await supabaseClient
                    .from("record_reports")
                    .insert(RecordReportInsertRequestDTO(from: report, reporterID: uid))
                    .execute()
            }
        )
    }()
}
