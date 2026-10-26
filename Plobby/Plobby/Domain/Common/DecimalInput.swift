//
//  DecimalInput.swift
//  Plobby
//
//  Created by 이은지 on 10/26/26.
//

import Foundation

enum DecimalInput {

    static let maximumFractionDigits = 1

    static func number(from text: String, locale: Locale) -> Double? {
        let trimmedText = InputText.trimmed(text)
        guard !trimmedText.isEmpty else { return nil }

        let decimalSeparator = locale.decimalSeparator ?? "."
        let parts = trimmedText.components(separatedBy: decimalSeparator)
        guard parts.count <= 2 else { return nil }

        let integerPart = parts[0]
        guard !integerPart.isEmpty, integerPart.allSatisfy(\.isASCIIDigit) else { return nil }

        guard parts.count == 2 else { return Double(integerPart) }

        let fractionPart = parts[1]
        guard !fractionPart.isEmpty,
                fractionPart.count <= maximumFractionDigits,
                fractionPart.allSatisfy(\.isASCIIDigit)
        else { return nil }

        return Double("\(integerPart).\(fractionPart)")
    }
}
