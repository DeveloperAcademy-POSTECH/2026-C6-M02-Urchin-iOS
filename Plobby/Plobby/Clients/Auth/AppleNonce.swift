//
//  AppleNonce.swift
//  Plobby
//
//  Created by 더스틴 on 10/27/26.
//

import CryptoKit
import Foundation

/// Apple 요청에는 해시값, Supabase에는 원래 값 보내기
enum AppleNonce {
    static let hexFormat = "%02x"
    
    static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: hexFormat, $0) }
            .joined()
    }
}
