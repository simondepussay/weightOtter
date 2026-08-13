//
//  Models.swift
//  Structures Codable mappées sur les tables Supabase
//  (profiles, entries, tracks).
//

import Foundation

// MARK: - Profil

struct Profile: Codable {
    var id: UUID
    var username: String
    var age: Int?     = nil
    var h: Double?    = nil   // taille (cm)
    var sex: String?  = "m"
    var act: Double?  = 1.55  // multiplicateur d'activité
    var goal: Double? = nil   // poids objectif
    var waist: Double? = nil
    var neck: Double?  = nil
    var hip: Double?   = nil
}

/// Charge utile d'update du profil (sans id ni username).
struct ProfileUpdate: Encodable {
    var age: Int?
    var h: Double?
    var sex: String?
    var act: Double?
    var goal: Double?
    var waist: Double?
    var neck: Double?
    var hip: Double?
}

// MARK: - Pesée

struct Entry: Codable, Identifiable {
    var id: UUID
    var userId: UUID
    var date: String   // "YYYY-MM-DD"
    var w: Double      // poids (kg)
    var cal: Int?      // calories de la veille
    var waist: Double?
    var hip: Double?

    enum CodingKeys: String, CodingKey {
        case id, date, w, cal, waist, hip
        case userId = "user_id"
    }
}

struct NewEntry: Encodable {
    let user_id: UUID
    let date: String
    let w: Double
    let cal: Int?
    let waist: Double?
    let hip: Double?
}

// MARK: - Compteur quotidien (TRACK)

struct TrackDay: Codable, Identifiable {
    var id: UUID
    var userId: UUID
    var date: String
    var cal: Int
    var protein: Int

    enum CodingKeys: String, CodingKey {
        case id, date, cal, protein
        case userId = "user_id"
    }
}

struct TrackUpsert: Encodable {
    let user_id: UUID
    let date: String
    let cal: Int
    let protein: Int
}

enum TrackField { case cal, protein }
