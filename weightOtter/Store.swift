//
//  Store.swift
//  Couche données : auth Supabase + cache observable.
//  Portage de storage.js / auth.js.
//

import Foundation
import Combine
import Supabase

@MainActor
final class Store: ObservableObject {

    @Published var username: String?
    @Published var profile: Profile?
    @Published var entries: [Entry] = []
    @Published var tracks: [TrackDay] = []
    @Published var loading = false
    @Published var authError: String?
    @Published var otterMessage: String?   // affiché dans la bulle de la loutre

    /// Clé i18n d'une erreur d'écriture (réseau / serveur). Présentée par
    /// MainTabView sous forme d'alerte : sans ça, une sauvegarde qui échoue
    /// passait totalement inaperçue et l'utilisateur croyait ses données
    /// enregistrées.
    @Published var opError: String?

    private func failed() { opError = "err.network" }

    private let client = SupabaseManager.client
    private var userId: UUID?

    var isLoggedIn: Bool { username != nil }

    // MARK: - Auth

    private func email(_ name: String) -> String {
        "\(name.lowercased())@weightotter.app"
    }

    /// Inscription avec contrôle d'unicité du nom.
    func signUp(username name: String, pin: String) async -> Bool {
        let clean = name.lowercased().trimmingCharacters(in: .whitespaces)
        authError = nil
        guard !clean.isEmpty else { authError = "err.noname"; return false }
        guard pin.count == 6 else { authError = "err.pin6"; return false }

        loading = true; defer { loading = false }
        do {
            let available: Bool = try await client
                .rpc("username_available", params: ["name": clean])
                .execute().value
            guard available else { authError = "err.taken"; return false }

            let res = try await client.auth.signUp(email: email(clean), password: pin)
            let uid = res.user.id
            do {
                try await client.from("profiles")
                    .insert(["id": uid.uuidString, "username": clean])
                    .execute()
            } catch {
                // Le compte Auth existe déjà mais son profil n'a pas pu être
                // créé. Sans nettoyage, ce nom devient définitivement
                // inutilisable : `username_available` le voit libre (pas de
                // profil) alors que signUp refusera l'e-mail déjà pris.
                // On efface donc le compte à moitié créé.
                _ = try? await client.rpc("delete_account").execute()
                try? await client.auth.signOut()
                print("signUp/profile:", error)
                authError = "err.signup"
                return false
            }

            userId = uid
            username = clean
            profile = Profile(id: uid, username: clean)
            entries = []
            tracks = []
            return true
        } catch {
            print("signUp:", error)
            authError = "err.signup"
            return false
        }
    }

    /// Connexion.
    func signIn(username name: String, pin: String) async -> Bool {
        let clean = name.lowercased().trimmingCharacters(in: .whitespaces)
        authError = nil
        guard !clean.isEmpty else { authError = "err.noname"; return false }
        guard pin.count == 6 else { authError = "err.pinshort"; return false }

        loading = true; defer { loading = false }
        do {
            let session = try await client.auth.signIn(email: email(clean), password: pin)
            try await loadCache(userId: session.user.id)
            return true
        } catch {
            authError = "err.wrong"
            return false
        }
    }

    func signOut() async {
        try? await client.auth.signOut()
        userId = nil
        username = nil
        profile = nil
        entries = []
        tracks = []
    }

    /// Suppression définitive du compte + de toutes les données.
    /// S'appuie sur la fonction RPC Supabase `delete_account`
    /// (SECURITY DEFINER) qui efface tracks / entries / profil / auth.users
    /// pour l'utilisateur courant (auth.uid()).
    func deleteAccount() async -> Bool {
        guard userId != nil else { return false }
        do {
            try await client.rpc("delete_account").execute()
            try? await client.auth.signOut()
            userId = nil
            username = nil
            profile = nil
            entries = []
            tracks = []
            return true
        } catch {
            print("deleteAccount:", error)
            return false
        }
    }

    /// Restaure une session existante au lancement.
    func restoreSession() async {
        do {
            let session = try await client.auth.session
            try await loadCache(userId: session.user.id)
        } catch {
            // pas de session active
        }
    }

    private func loadCache(userId uid: UUID) async throws {
        userId = uid
        let profs: [Profile] = try await client.from("profiles")
            .select().eq("id", value: uid.uuidString).execute().value
        let ents: [Entry] = try await client.from("entries")
            .select().eq("user_id", value: uid.uuidString).order("date").execute().value
        let trks: [TrackDay] = try await client.from("tracks")
            .select().eq("user_id", value: uid.uuidString).order("date").execute().value
        profile  = profs.first
        username = profs.first?.username
        entries  = ents
        tracks   = trks
    }

    // MARK: - Pesées

    func addEntry(date: String, w: Double, cal: Int?, waist: Double?, hip: Double?) async -> Bool {
        guard let uid = userId else { return false }
        if entries.contains(where: { $0.date == date }) { return false }
        do {
            let new = NewEntry(user_id: uid, date: date, w: w, cal: cal, waist: waist, hip: hip)
            let saved: Entry = try await client.from("entries")
                .insert(new).select().single().execute().value
            entries.append(saved)
            entries.sort { $0.date < $1.date }
            return true
        } catch {
            print("addEntry:", error)
            failed()
            return false
        }
    }

    func deleteEntry(_ entry: Entry) async {
        do {
            try await client.from("entries")
                .delete().eq("id", value: entry.id.uuidString).execute()
            entries.removeAll { $0.id == entry.id }
        } catch {
            print("deleteEntry:", error)
            failed()
        }
    }

    // MARK: - Profil

    func saveProfile(_ p: Profile) async {
        guard let uid = userId else { return }
        do {
            let upd = ProfileUpdate(age: p.age, h: p.h, sex: p.sex, act: p.act,
                                    goal: p.goal, waist: p.waist, neck: p.neck, hip: p.hip)
            try await client.from("profiles")
                .update(upd).eq("id", value: uid.uuidString).execute()
            profile = p
        } catch {
            print("saveProfile:", error)
            failed()
        }
    }

    // MARK: - TRACK (compteurs quotidiens)

    func todayTrack() -> TrackDay? { tracks.first { $0.date == DateHelper.today } }

    func track(for date: String) -> TrackDay? { tracks.first { $0.date == date } }

    /// Fixe directement une valeur (digicode) — date au choix.
    func setTrack(field: TrackField, value: Int, date: String) async {
        guard let uid = userId else { return }
        let existing = tracks.first { $0.date == date }
        var cal = existing?.cal ?? 0
        var protein = existing?.protein ?? 0
        switch field {
        case .cal:     cal = max(0, value)
        case .protein: protein = max(0, value)
        }
        do {
            let payload = TrackUpsert(user_id: uid, date: date, cal: cal, protein: protein)
            let saved: TrackDay = try await client.from("tracks")
                .upsert(payload, onConflict: "user_id,date")
                .select().single().execute().value
            if let idx = tracks.firstIndex(where: { $0.date == date }) {
                tracks[idx] = saved
            } else {
                tracks.append(saved)
                tracks.sort { $0.date < $1.date }
            }
        } catch {
            print("setTrack:", error)
            failed()
        }
    }

    func deleteTrack(date: String) async {
        guard let row = tracks.first(where: { $0.date == date }) else { return }
        do {
            try await client.from("tracks")
                .delete().eq("id", value: row.id.uuidString).execute()
            tracks.removeAll { $0.date == date }
        } catch {
            print("deleteTrack:", error)
            failed()
        }
    }
}
