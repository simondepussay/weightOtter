//
//  RootView.swift
//  Aiguillage : écran de connexion ou app principale.
//

import SwiftUI
import Foundation
import Combine
import Supabase

struct RootView: View {
    @EnvironmentObject var store: Store
    @State private var checked = false

    var body: some View {
        ZStack {
            Color.woBg.ignoresSafeArea()

            if !checked {
                ProgressView()
                    .tint(.woBlue)
            } else if store.isLoggedIn {
                MainTabView()
            } else {
                AuthView()
            }
        }
        .task {
            await store.restoreSession()
            checked = true

            // Consentement publicitaire (UMP puis ATT) seulement ICI :
            // RootView n'apparaît qu'une fois l'avertissement santé accepté.
            // Lancé depuis la scène, le popup de suivi Apple s'empilait
            // par-dessus cet avertissement au tout premier démarrage — mauvais
            // pour le taux d'acceptation, et risqué en revue App Store.
            await AdManager.shared.start()
        }
    }
}
