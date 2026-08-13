//
//  AppLinks.swift
//  Adresses externes de l'app, regroupées ici pour n'avoir qu'un seul
//  endroit à modifier le jour où le site change d'hébergeur.
//

import Foundation

enum AppLinks {

    /// Adresse de support (bouton « ? »).
    static let supportEmail = "rt9app@gmail.com"

    /// Politique de confidentialité — hébergée avec le site WeightOtter.
    /// Page source : `~/Desktop/WeightOtter/privacy.html`.
    ///
    /// La MÊME URL doit être renseignée dans App Store Connect, champ
    /// « URL de la politique de confidentialité » — obligatoire pour publier.
    static let privacyPolicy = URL(string:
        "https://adorable-dusk-fe2417.netlify.app/privacy.html")!
}
