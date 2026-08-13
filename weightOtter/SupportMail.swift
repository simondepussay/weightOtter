//
//  SupportMail.swift
//  Bouton d'aide : ouvre l'app Mail avec un message pré-rempli
//  vers le support (PIN oublié, question, bug…).
//  Repli : si aucune app Mail, propose de copier l'adresse.
//

import SwiftUI
import UIKit

struct HelpButton: View {
    @EnvironmentObject var loc: Localizer
    @Environment(\.openURL) private var openURL

    /// Nom de compte à inclure dans le message (facultatif).
    var username: String? = nil

    @State private var showFallback = false

    private let supportEmail = AppLinks.supportEmail

    var body: some View {
        Button {
            if let url = mailtoURL() {
                openURL(url) { accepted in
                    if !accepted { showFallback = true }
                }
            } else {
                showFallback = true
            }
        } label: {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 18))
                .foregroundColor(.woBlue)
        }
        .accessibilityLabel(loc.t("help.title"))
        .alert(loc.t("help.fallback.title"), isPresented: $showFallback) {
            Button(loc.t("help.copy")) { UIPasteboard.general.string = supportEmail }
            Button("OK", role: .cancel) { }
        } message: {
            Text("\(loc.t("help.fallback.msg"))\n\(supportEmail)")
        }
    }

    private func mailtoURL() -> URL? {
        let subject = loc.t("help.subject")
        var body = loc.t("help.body")
        if let u = username?.trimmingCharacters(in: .whitespaces), !u.isEmpty {
            body += "\n\n\(loc.t("help.account")) \(u)"
        }
        let allowed = CharacterSet.urlQueryAllowed
        let s = subject.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
        let b = body.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
        return URL(string: "mailto:\(supportEmail)?subject=\(s)&body=\(b)")
    }
}
