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
    case recordExitConfirm
    case favoriteBeachLimit
    
}

extension AlertType {
    
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
        case .recordExitConfirm: "작성 중인 글을 나가시겠습니까?"
        case .favoriteBeachLimit: "관심 해변을 더 추가할 수 없어요"
        }
    }
    
    var message: String? {
        switch self {
        case .signInFailed, .signUpFailed, .recordSubmitFailed, .recordDeleteFailed, .profileUpdateFailed: "잠시 후 다시 시도해 주세요."
        case .profileImageTooLarge: "2MB 미만의 사진을 선택해 주세요."
        case .recordDeleteConfirm: "삭제한 기록은 복구할 수 없어요."
        case .recordDeleted: nil
        case .userBlockConfirm: "차단하면 이 사용자의 기록이 더 이상 보이지 않아요."
        case .recordExitConfirm: "지금 나가면 작성한 내용은 저장되지 않아요."
        case .favoriteBeachLimit: "관심 해변은 최대 \(HomeFeature.maximumFavoriteBeachCount)개까지 등록할 수 있어요."
        }
    }
    
    var buttonType: ButtonType {
        switch self {
        case .recordSubmitFailed, .recordDeleteConfirm, .userBlockConfirm, .recordExitConfirm: .cancelConfirm
        case .signInFailed, .signUpFailed, .profileImageTooLarge, .recordDeleted, .recordDeleteFailed, .profileUpdateFailed, .favoriteBeachLimit: .confirm
        }
    }
    
    var confirmTitle: String {
        switch self {
        case .signInFailed, .signUpFailed, .profileImageTooLarge, .recordDeleted, .recordDeleteFailed, .profileUpdateFailed, .favoriteBeachLimit: "확인"
        case .recordSubmitFailed: "다시 시도"
        case .recordDeleteConfirm: "삭제"
        case .userBlockConfirm: "차단"
        case .recordExitConfirm: "계속 작성하기"
        }
    }
    
    var cancelTitle: String {
        switch self {
        case .recordExitConfirm: "나가기"
        default: "취소"
        }
    }
}

extension AlertType {
    
    enum ButtonType: Equatable {
        case confirm
        case cancelConfirm
    }
}
