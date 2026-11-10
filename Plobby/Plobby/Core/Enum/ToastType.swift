//
//  ToastType.swift
//  Plobby
//
//  Created by dlsundn on 11/10/26.
//

import Foundation

enum ToastType: Equatable {
    
    case photoLimitExceeded
    case photoSaveFailed
    case favoriteBeachRemoved
    case favoriteBeachAddFailed
    case favoriteBeachRemoveFailed
    case favoriteBeachRestoreFailed
    case favoriteBeachLimitReached
    case userBlocked(nickname: String)
    case userUnblocked(nickname: String)
    case userBlockFailed
    case userUnblockFailed
    
    var message: String {
        switch self {
        case .photoLimitExceeded: "사진은 최대 \(PhotoSelection.maxCount)장까지 선택할 수 있어요."
        case .photoSaveFailed: "사진을 저장하지 못했어요. 다시 시도해주세요."
        case .favoriteBeachRemoved: "관심 해변을 해제했어요"
        case .favoriteBeachAddFailed: "관심 해변을 추가하지 못했어요"
        case .favoriteBeachRemoveFailed: "관심 해변을 해제하지 못했어요"
        case .favoriteBeachRestoreFailed: "관심 해변을 되돌리지 못했어요"
        case .favoriteBeachLimitReached: "관심 해변은 최대 \(Beach.maximumFavoriteCount)개까지 등록할 수 있어요"
        case let .userBlocked(nickname): "\(nickname)님을 차단했어요"
        case let .userUnblocked(nickname): "\(nickname)님 차단을 해제했어요"
        case .userBlockFailed: "차단하지 못했어요"
        case .userUnblockFailed: "차단을 해제하지 못했어요"
        }
    }
    
    /// 오른쪽 버튼 문구예요. 버튼이 없는 토스트는 nil이에요.
    var actionTitle: String? {
        switch self {
        case .favoriteBeachRemoved: "되돌리기"
        default: nil
        }
    }
}
