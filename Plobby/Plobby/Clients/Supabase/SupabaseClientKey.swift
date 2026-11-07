//
//  SupabaseClientKey.swift
//  Plobby
//
//  Created by 더스틴 on 10/27/26.
//

import Dependencies
import Supabase

nonisolated struct SupabaseClientKey: DependencyKey {
    
    static let liveValue: SupabaseClient = {
        SupabaseClient(
            supabaseURL: Secrets.supabaseURL,
            supabaseKey: Secrets.supabaseKey,
            options: SupabaseClientOptions(
                auth: .init(emitLocalSessionAsInitialSession: true)
            )
        )
    }()
}
