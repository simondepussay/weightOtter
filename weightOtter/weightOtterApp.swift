//
//  WeightOtterApp.swift
//  Point d'entrée. Affiche d'abord l'avertissement santé,
//  puis l'app (login ou écran principal selon la session).
//

import SwiftUI

@main
struct WeightOtterApp: App {
    @StateObject private var store = Store()
    @StateObject private var loc = Localizer()
    @AppStorage("disclaimerAccepted") private var disclaimerAccepted = false
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashView {
                        withAnimation(.easeOut(duration: 0.5)) { showSplash = false }
                    }
                } else if disclaimerAccepted {
                    RootView()
                } else {
                    DisclaimerView(accepted: $disclaimerAccepted)
                }
            }
            .environmentObject(store)
            .environmentObject(loc)
            .preferredColorScheme(.dark)
            .task {
                // Consentement (UMP puis ATT) + démarrage du SDK publicitaire.
                await AdManager.shared.start()
            }
        }
    }
}
