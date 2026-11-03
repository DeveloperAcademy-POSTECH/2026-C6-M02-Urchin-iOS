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
    
    var title: String {
        switch self {
        case .signInFailed: "로그인하지 못했어요"
        case .signUpFailed: "회원가입을 완료하지 못했어요"
        case .profileImageTooLarge: "사진을 사용할 수 없어요"
        }
    }
    
    var message: String? {
        switch self {
        case .signInFailed, .signUpFailed: "잠시 후 다시 시도해 주세요."
        case .profileImageTooLarge: "2MB 미만의 사진을 선택해 주세요."
        }
    }
    
    var buttonType: ButtonType {
        switch self {
        case .signInFailed, .signUpFailed, .profileImageTooLarge: .confirm
        }
    }
    
    var confirmTitle: String {
        switch self {
        case .signInFailed, .signUpFailed, .profileImageTooLarge: "확인"
        }
    }
}

extension AlertType {
    
    enum ButtonType: Equatable {
        case confirm
    }
}
