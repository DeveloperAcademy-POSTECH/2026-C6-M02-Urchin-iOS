//
//  Nickname.swift
//  Plobby
//
//  Created by 이은지 on 10/26/26.
//

import Foundation

enum Nickname {
    
    static let minimumLength = 2
    static let maximumLength = 50
    
    static func isValid(_ nickname: String) -> Bool {
        (minimumLength...maximumLength).contains(InputText.trimmed(nickname).count)
    }
}
