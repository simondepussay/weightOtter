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
        }
    }
}
