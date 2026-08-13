//
//  AuthView.swift
//  Connexion / création de compte avec PIN 6 chiffres.
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var loc: Localizer

    @State private var mode: Mode = .login
    @State private var name = ""
    @State private var pin = ""

    enum Mode { case login, register }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image("spaceotter")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 92, height: 92)
                    .padding(.top, 26)

                Text("⚖ WEIGHTOTTER")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.woBlue)

                // Bascule connexion / création
                HStack(spacing: 0) {
                    modeButton(loc.t("auth.login"), .login)
                    modeButton(loc.t("auth.register"), .register)
                }
                .background(Color.woCard)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.woBorder))
                .cornerRadius(8)

                // Nom d'utilisateur
                VStack(alignment: .leading, spacing: 4) {
                    Text(loc.t("auth.username"))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.woText2)
                    TextField(loc.t("auth.username.ph"), text: $name)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(10)
                        .background(Color.woBg)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.woBorder))
                        .foregroundColor(.woText)
                }

                // PIN
                VStack(spacing: 10) {
                    Text(loc.t("auth.pin"))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.woText2)
                    HStack(spacing: 10) {
                        ForEach(0..<6, id: \.self) { i in
                            Circle()
                                .fill(i < pin.count ? Color.woBlue : Color.clear)
                                .frame(width: 14, height: 14)
                                .overlay(Circle().stroke(Color.woBlue3, lineWidth: 2))
                        }
                    }
                }

                PinPad(pin: $pin) {
                    Task { await submit() }
                }

                if let err = store.authError {
                    Text(loc.t(err))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.woRed)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await submit() }
                } label: {
                    Text(mode == .login ? loc.t("auth.btn.login") : loc.t("auth.btn.register"))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .frame(maxWidth: .infinity)
                        .padding(13)
                        .background(Color.woBlue3)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(store.loading)
            }
            .padding(20)
        }
        .overlay(alignment: .topTrailing) {
            HelpButton(username: name)
                .padding(.top, 8)
                .padding(.trailing, 16)
        }
    }

    private func modeButton(_ label: String, _ m: Mode) -> some View {
        Button {
            mode = m; pin = ""; store.authError = nil
        } label: {
            Text(label)
                .font(.system(size: 13, design: .monospaced))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(mode == m ? Color.woBlue3 : Color.clear)
                .foregroundColor(mode == m ? .white : .woText2)
        }
    }

    private func submit() async {
        let ok = mode == .login
            ? await store.signIn(username: name, pin: pin)
            : await store.signUp(username: name, pin: pin)
        if !ok { pin = "" }
    }
}

// MARK: - Pavé PIN

struct PinPad: View {
    @Binding var pin: String
    var onComplete: () -> Void

    private let keys = ["1","2","3","4","5","6","7","8","9","","0","⌫"]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(spacing: 8), count: 3), spacing: 8) {
            ForEach(keys, id: \.self) { k in
                if k.isEmpty {
                    Color.clear.frame(height: 54)
                } else {
                    Button {
                        tap(k)
                    } label: {
                        Text(k)
                            .font(.system(size: 22, design: .monospaced))
                            .frame(maxWidth: .infinity, minHeight: 54)
                            .background(Color.woCard)
                            .foregroundColor(.woText)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.woBorder))
                            .cornerRadius(8)
                    }
                }
            }
        }
    }

    private func tap(_ k: String) {
        if k == "⌫" {
            if !pin.isEmpty { pin.removeLast() }
        } else if pin.count < 6 {
            pin += k
            if pin.count == 6 { onComplete() }
        }
    }
}
