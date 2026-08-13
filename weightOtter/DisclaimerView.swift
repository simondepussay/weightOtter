//
//  DisclaimerView.swift
//  Avertissement santé affiché au premier lancement.
//

import SwiftUI

struct DisclaimerView: View {
    @EnvironmentObject var loc: Localizer
    @Binding var accepted: Bool

    var body: some View {
        ZStack {
            Color.woBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    Image("spaceotter")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .padding(.top, 36)

                    Text("⚖ WEIGHTOTTER")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.woBlue)

                    Text(loc.t("disc.warning"))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.woText2)

                    VStack(alignment: .leading, spacing: 14) {
                        bullet(loc.t("disc.b1"))
                        bullet(loc.t("disc.b2"))
                        bullet(loc.t("disc.b3"))
                        bullet(loc.t("disc.b4"))
                        bullet(loc.t("disc.b5"))
                    }
                    .padding(16)
                    .background(Color.woCard)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.woBorder))
                    .cornerRadius(12)

                    Button {
                        accepted = true
                    } label: {
                        Text(loc.t("disc.btn"))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(Color.woBlue3)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(20)
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•").foregroundColor(.woBlue)
            Text(text)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.woText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// Petit rappel réutilisable (bas de l'écran Profil).
struct DisclaimerFooter: View {
    @EnvironmentObject var loc: Localizer
    var body: some View {
        Text(loc.t("disc.footer"))
            .font(.system(size: 10, design: .monospaced))
            .foregroundColor(.woText2)
            .multilineTextAlignment(.center)
            .padding(.vertical, 8)
    }
}
