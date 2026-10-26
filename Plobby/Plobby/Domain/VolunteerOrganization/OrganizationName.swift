//
//  OrganizationName.swift
//  Plobby
//
//  Created by 이은지 on 10/26/26.
//

import Foundation

enum OrganizationName {
    
    static let minimumLength = 1
    static let maximumLength = 20
    
    static func isValid(_ name: String) -> Bool {
        InputText.isValid(name, length: minimumLength...maximumLength) {
            $0.isHangul || $0.isEnglishLetter || $0.isASCIIDigit || $0 == " "
        }
    }
}
