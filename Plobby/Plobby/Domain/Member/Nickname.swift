//
//  Nickname.swift
//  Plobby
//
//  Created by 이은지 on 10/26/26.
//

import Foundation

enum Nickname {
    
    static let minimumLength = 2
    static let maximumLength = 10
    
    static func isValid(_ nickname: String) -> Bool {
        InputText.isValid(nickname, length: minimumLength...maximumLength) {
            $0.isHangul || $0.isEnglishLetter || $0.isASCIIDigit
        }
    }
}
