//
//  ReportReason.swift
//  Plobby
//
//  Created by dlsundn on 11/13/26.
//

import Foundation

/// 기록 신고 사유예요. rawValue는 서버 `record_reports.reason` 값이에요.
nonisolated enum ReportReason: String, CaseIterable, Sendable {
    case spamAd = "spam_ad"
    case inappropriatePhoto = "inappropriate_photo"
    case falseRecord = "false_record"
    case abuse
    /// 기타. 직접 쓴 내용은 `reason_detail`에 저장해요.
    case other

    /// 목록에서 고르는 사유예요. 기타는 아래 입력칸에 직접 써요.
    static var selectableCases: [ReportReason] {
        allCases.filter { $0 != .other }
    }

    var title: String {
        switch self {
        case .spamAd: "스팸이나 광고성 기록이에요"
        case .inappropriatePhoto: "부적절한 사진이 포함되어 있어요"
        case .falseRecord: "사실과 다른 허위 기록이에요"
        case .abuse: "욕설이나 비방이 담겨 있어요"
        case .other: "기타"
        }
    }
}
