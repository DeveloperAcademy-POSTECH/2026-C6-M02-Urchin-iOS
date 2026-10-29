//
//  RecordMemo.swift
//  Plobby
//
//  Created by 이은지 on 10/26/26.
//

import Foundation

enum RecordMemo {
    
    static let maximumLength = 500
    
    static func isValid(_ memo: String) -> Bool {
        InputText.isValid(memo, length: 0...maximumLength) { !$0.isEmoji }
    }
}
