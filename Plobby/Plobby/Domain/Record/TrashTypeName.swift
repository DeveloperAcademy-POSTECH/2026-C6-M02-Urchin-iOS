//
//  TrashTypeName.swift
//  Plobby
//
//  Created by 이은지 on 10/26/26.
//

import Foundation

enum TrashTypeName {
    
    static let minimumLength = 1
    static let maximumLength = 20
    
    static func isValid(_ name: String) -> Bool {
        let trimmedName = InputText.trimmed(name)
        return (minimumLength...maximumLength).contains(trimmedName.count)
            && trimmedName.allSatisfy { $0.isHangul || $0.isEnglishLetter || $0.isASCIIDigit || $0 == " " || $0 == "·" }
    }
}
