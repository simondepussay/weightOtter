//
//  SupabaseManager.swift
//  Client Supabase partagé — MÊME projet que l'app web,
//  donc mêmes comptes et mêmes données.
//

import Foundation
import Supabase

enum SupabaseManager {
    static let client = SupabaseClient(
        supabaseURL: URL(string: Secrets.supabaseURL)!,
        supabaseKey: Secrets.supabaseKey
    )
}
