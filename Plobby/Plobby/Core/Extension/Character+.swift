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
}
