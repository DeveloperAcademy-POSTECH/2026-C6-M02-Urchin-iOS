//
//  DependencyValues+SupabaseClient.swift
//  Plobby
//
//  Created by 더스틴 on 10/29/26.
//

import Dependencies
import Supabase

extension DependencyValues {
    
    var supabaseClient: SupabaseClient {
        get { self[SupabaseClientKey.self] }
        set { self[SupabaseClientKey.self] = newValue }
    }
}
