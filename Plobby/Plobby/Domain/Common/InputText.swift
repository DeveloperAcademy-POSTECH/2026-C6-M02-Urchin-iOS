//
//  InputText.swift
//  Plobby
//
//  Created by 이은지 on 10/26/26.
//

import Foundation

enum InputText {

    static func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
 
    static func isBlank(_ text: String) -> Bool {
        trimmed(text).isEmpty
    }
}
