//
//  Theme.swift
//  Palette inspirée de l'app web (fond sombre, bleu clair, vert CRT).
//

import SwiftUI

extension Color {
    static let woBg     = Color(red: 0.031, green: 0.024, blue: 0.071)
    static let woCard   = Color(red: 0.071, green: 0.047, blue: 0.165)
    static let woBlue   = Color(red: 0.310, green: 0.764, blue: 0.969)
    static let woBlue3  = Color(red: 0.008, green: 0.533, blue: 0.820)
    static let woGreen  = Color(red: 0.302, green: 1.0,   blue: 0.470)
    static let woPurple = Color(red: 0.808, green: 0.576, blue: 0.847)
    static let woText   = Color(red: 0.800, green: 0.910, blue: 0.957)
    static let woText2  = Color(red: 0.416, green: 0.604, blue: 0.710)
    static let woRed    = Color(red: 0.937, green: 0.325, blue: 0.314)
    static let woBorder = Color(red: 0.310, green: 0.764, blue: 0.969).opacity(0.18)
}

/// Style de carte commun (fond sombre + bordure bleutée).
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.woCard)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.woBorder))
            .cornerRadius(10)
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }

    /// Ferme le clavier quand on touche en dehors d'un champ.
    func dismissKeyboardOnTap() -> some View {
        onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil)
        }
    }
}

