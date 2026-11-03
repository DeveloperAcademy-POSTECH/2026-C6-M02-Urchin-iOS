//
//  SupabaseClient+.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import Foundation

import Supabase

extension SupabaseClient {
    
    func currentUserID() async throws -> UUID {
        try await auth.session.user.id
    }
}
