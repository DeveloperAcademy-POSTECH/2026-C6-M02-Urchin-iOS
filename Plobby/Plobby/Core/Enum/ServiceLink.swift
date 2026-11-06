//
//  ServiceLink.swift
//  Plobby
//
//  Created by 이은지 on 11/7/26.
//

import Foundation

/// 공지사항·문의·약관 등 서비스 안내 링크 (설정, 회원가입 약관 동의에서 사용)
enum ServiceLink: CaseIterable {
    case notice
    case inquiry
    case termsOfService
    case privacyPolicy

    var title: String {
        switch self {
        case .notice: "공지사항"
        case .inquiry: "문의하기"
        case .termsOfService: "이용약관"
        case .privacyPolicy: "개인정보 처리방침"
        }
    }

    var url: URL? {
        switch self {
        case .notice: URL(string: "https://root-fenugreek-5da.notion.site/4100af7877f48126a2edd352e419e39c")
        case .inquiry: URL(string: "https://root-fenugreek-5da.notion.site/4100af7877f481aa9461d6e7c64e0bcf")
        case .termsOfService: URL(string: "https://root-fenugreek-5da.notion.site/4100af7877f4819fa959e6f62de599bc")
        case .privacyPolicy: URL(string: "https://root-fenugreek-5da.notion.site/4100af7877f48117be23c849a2a2c5f9")
        }
    }
}
