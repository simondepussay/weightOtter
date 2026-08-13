//
//  MainTabView.swift
//  Onglets principaux : Liste / Graphique / Track / Profil.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var loc: Localizer
    @EnvironmentObject var store: Store

    /// Une écriture échouée (réseau coupé, session expirée…) doit se voir :
    /// `store.opError` porte la clé i18n, on la présente ici pour tous
    /// les onglets à la fois.
    private var showError: Binding<Bool> {
        Binding(get: { store.opError != nil },
                set: { if !$0 { store.opError = nil } })
    }

    var body: some View {
        TabView {
            EntriesView()
                .tabItem { Label(loc.t("tab.list"), systemImage: "list.bullet") }

            ChartView()
                .tabItem { Label(loc.t("tab.chart"), systemImage: "chart.xyaxis.line") }

            TrackView()
                .tabItem { Label(loc.t("tab.track"), systemImage: "flame") }

            SummaryView()
                .tabItem { Label(loc.t("tab.summary"), systemImage: "chart.bar") }

            ProfileView()
                .tabItem { Label(loc.t("tab.profile"), systemImage: "person") }
        }
        .tint(.woBlue)
        .alert(loc.t("err.network.title"), isPresented: showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(loc.t(store.opError ?? "err.network"))
        }
    }
}
