//
//  Character+.swift
//  Plobby
//
//  Created by 이은지 on 10/26/26.
//

extension Character {
    
    var isEmoji: Bool {
        guard let firstScalar = unicodeScalars.first else { return false }
        if firstScalar.properties.isEmojiPresentation { return true }
        
        return firstScalar.properties.isEmoji && unicodeScalars.count > 1
    }
    
    var isHangul: Bool {
        guard unicodeScalars.count == 1, let scalar = unicodeScalars.first else { return false }
        return (0xAC00...0xD7A3).contains(scalar.value)
    }
    
    var isEnglishLetter: Bool {
        isASCII && isLetter
    }
    
    nonisolated var isASCIIDigit: Bool {
        isASCII && isNumber
    }
}
