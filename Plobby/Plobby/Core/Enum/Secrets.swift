//
//  Secrets.swift
//  Plobby
//
//  Created by 더스틴 on 10/27/26.
//

import Foundation

enum Secrets {
    static let supabaseURL: URL = {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            let url = URL(string: value)
        else {
            fatalError("SUPABASE_URL이 설정되지 않았어요. Config.xcconfig를 확인하세요.")
        }
        return url
    }()
    
    static let supabaseKey: String = {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_KEY") as? String,
              !value.isEmpty
        else {
            fatalError("SUPABASE_KEY가 설정되지 않았어요.")
        }
        return value
    }()
}
