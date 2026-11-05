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

extension DecimalInput {

    /// 저장된 숫자를 입력칸에 다시 채울 때 써요. 소수점 첫째 자리까지만 보여요.
    static func text(from number: Double) -> String {
        number.formatted(.number.precision(.fractionLength(0...maximumFractionDigits)).grouping(.never))
    }
}
