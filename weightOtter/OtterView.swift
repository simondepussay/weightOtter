//
//  OtterView.swift
//  Mascotte cliquable : la loutre de l'espace livre des encouragements,
//  des fun facts absurdes du futur — et les messages d'erreur de l'app.
//

import SwiftUI

/// Loutre ronde et cliquable — affiche une bulle de dialogue.
/// Le message vient de `store.otterMessage` : aléatoire au tap,
/// ou imposé ailleurs dans l'app (ex. erreur de saisie).
struct OtterMascot: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var loc: Localizer
    var size: CGFloat = 40

    var body: some View {
        Image("spaceotter")
            .resizable()
            .renderingMode(.original)
            .scaledToFit()
            .frame(width: size, height: size)
            .padding(6)
            .background(Circle().fill(Color.woCard))
            .overlay(Circle().stroke(Color.woBlue.opacity(0.45), lineWidth: 2))
            .onTapGesture { store.otterMessage = loc.otterMessage() }
            .popover(isPresented: Binding(
                get: { store.otterMessage != nil },
                set: { if !$0 { store.otterMessage = nil } }
            )) {
                VStack(spacing: 10) {
                    HStack(spacing: 6) {
                        Image("spaceotter")
                            .resizable()
                            .renderingMode(.original)
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .scaleEffect(x: -1, y: 1)   // miroir horizontal
                        Text(loc.t("otter.title"))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.woBlue)
                    }
                    Text(store.otterMessage ?? "")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.woText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(18)
                .frame(width: 260)
                .presentationCompactAdaptation(.popover)
            }
    }
}
