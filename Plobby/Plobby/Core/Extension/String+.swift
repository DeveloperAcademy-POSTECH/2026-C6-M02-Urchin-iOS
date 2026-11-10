//
//  String+.swift
//  Plobby
//
//  Created by 이은지 on 11/9/26.
//

extension String {

    /// 마지막 글자에 받침이 있으면 "을", 없으면 "를" (예: 나무를, 금속을)
    /// 한글로 끝나지 않으면 "을(를)"을 돌려줍니다.
    var objectParticle: String {
        guard let scalar = last?.unicodeScalars.first?.value, (0xAC00...0xD7A3).contains(scalar) else {
            return "을(를)"
        }
        return (scalar - 0xAC00) % 28 == 0 ? "를" : "을"
    }
}
