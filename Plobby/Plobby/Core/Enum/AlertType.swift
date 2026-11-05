//
//  AlertType.swift
//  Plobby
//
//  Created by 더스틴 on 10/29/26.
//

import Foundation

enum AlertType {
    
    case signInFailed
    case signUpFailed
    case profileImageTooLarge
    case recordSubmitFailed
    case recordDeleteConfirm
    case recordDeleted
    case recordDeleteFailed
    case userBlockConfirm
    case profileUpdateFailed
    
    var title: String {
        switch self {
        case .signInFailed: "로그인하지 못했어요"
        case .signUpFailed: "회원가입을 완료하지 못했어요"
        case .profileImageTooLarge: "사진을 사용할 수 없어요"
        case .recordSubmitFailed: "기록을 저장하지 못했어요"
        case .recordDeleteConfirm: "기록을 삭제할까요?"
        case .recordDeleted: "삭제가 완료되었습니다"
        case .recordDeleteFailed: "기록을 삭제하지 못했어요"
        case .userBlockConfirm: "이 사용자를 차단할까요?"
        case .profileUpdateFailed: "프로필을 저장하지 못했어요"
        }
    }
    
    var message: String? {
        switch self {
        case .signInFailed, .signUpFailed, .recordSubmitFailed, .recordDeleteFailed, .profileUpdateFailed: "잠시 후 다시 시도해 주세요."
        case .profileImageTooLarge: "2MB 미만의 사진을 선택해 주세요."
        case .recordDeleteConfirm: "삭제한 기록은 복구할 수 없어요."
        case .recordDeleted: nil
        case .userBlockConfirm: "차단하면 이 사용자의 기록이 더 이상 보이지 않아요."
        }
    }
    
    var buttonType: ButtonType {
        switch self {
        case .recordSubmitFailed, .recordDeleteConfirm, .userBlockConfirm: .cancelConfirm
        case .signInFailed, .signUpFailed, .profileImageTooLarge, .recordDeleted, .recordDeleteFailed, .profileUpdateFailed: .confirm
        }
    }
    
    var confirmTitle: String {
        switch self {
        case .signInFailed, .signUpFailed, .profileImageTooLarge, .recordDeleted, .recordDeleteFailed, .profileUpdateFailed: "확인"
        case .recordSubmitFailed: "다시 시도"
        case .recordDeleteConfirm: "삭제"
        case .userBlockConfirm: "차단"
        }
    }
    
    /// 되돌릴 수 없는 동작은 확인 버튼을 빨간색으로 보여줘요.
    var isDestructive: Bool {
        switch self {
        case .recordDeleteConfirm, .userBlockConfirm: true
        default: false
        }
    }
}

extension AlertType {
    
    enum ButtonType: Equatable {
        case confirm
        case cancelConfirm
    }
}
