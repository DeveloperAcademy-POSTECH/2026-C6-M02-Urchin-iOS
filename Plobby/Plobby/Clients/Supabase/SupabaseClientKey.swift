//
//  SupabaseClientKey.swift
//  Plobby
//
//  Created by 더스틴 on 10/27/26.
//

import Dependencies
import Supabase

struct SupabaseClientKey: DependencyKey {
    
    static var liveValue: SupabaseClient = {
        SupabaseClient(
            supabaseURL: Secrets.supabaseURL,
            supabaseKey: Secrets.supabaseKey,
            options: SupabaseClientOptions(
                auth: .init(emitLocalSessionAsInitialSession: true)
            )
        )
    }()
}
