//
//  AdManager.swift
//  Publicités interstitielles Google AdMob.
//
//  La pub n'est pas collée à un bouton : on déclare des « moments »
//  (saisie d'une calorie, ajout d'une pesée…) et le manager décide,
//  en respectant quatre garde-fous :
//     1. une probabilité par moment      → aléatoire, jamais systématique
//     2. un délai minimum entre 2 pubs   → cooldown
//     3. un plafond par jour             → maxPerDay
//     4. une période de grâce au lancement
//
//  Chaîne de consentement : UMP (obligatoire en Europe) puis ATT (IDFA).
//  Sans consentement au suivi, on sert des annonces NON personnalisées —
//  c'est légal et ça rapporte quand même.
//

import SwiftUI
import Combine
import UIKit
import AppTrackingTransparency
import GoogleMobileAds
import UserMessagingPlatform

// MARK: - Moments publicitaires

enum AdTrigger {
    case calorie      // saisie d'un nombre de calories
    case protein      // saisie de protéines
    case weighIn      // ajout d'une pesée

    /// Probabilité d'affichage pour ce moment (0 = jamais, 1 = toujours).
    var probability: Double {
        switch self {
        case .calorie: return 0.25   // 1 fois sur 4
        case .protein: return 0.15
        case .weighIn: return 0.35
        }
    }
}

// MARK: - Réglages

enum AdConfig {
    /// Coupe-circuit global : `false` = aucune pub nulle part.
    static let enabled = true

    /// Bloc interstitiel AdMob (compte weightOtter).
    /// Séparateur : barre oblique / pour un bloc d'annonces — à ne pas
    /// confondre avec le tilde ~ de `GADApplicationIdentifier`.
    ///
    /// Sur simulateur, le SDK sert automatiquement des annonces de test,
    /// même avec cet identifiant réel : rien n'est compté en développement.
    static let interstitialUnitID = "ca-app-pub-9526420306965592/6616524551"

    static let cooldown: TimeInterval  = 3 * 60   // 3 min entre deux pubs
    static let maxPerDay               = 6        // plafond quotidien
    static let grace: TimeInterval     = 60       // rien dans la 1re minute
}

// MARK: - Manager

@MainActor
final class AdManager: NSObject, ObservableObject {

    static let shared = AdManager()

    private var interstitial: GADInterstitialAd?
    private var loading = false
    private var showing = false

    private let launchedAt = Date()
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let last  = "adLastShown"
        static let count = "adCountToday"
        static let day   = "adCountDay"
    }

    private override init() { super.init() }

    // MARK: Démarrage

    /// À appeler une fois au lancement : consentement puis init du SDK.
    func start() async {
        guard AdConfig.enabled else { return }
        await requestConsent()
        await requestTrackingAuthorizationIfNeeded()

        GADMobileAds.sharedInstance().start(completionHandler: nil)
        await preload()
    }

    /// Formulaire de consentement Google (UMP). Obligatoire en Europe,
    /// sans effet ailleurs.
    private func requestConsent() async {
        let params = UMPRequestParameters()
        #if DEBUG
        // En debug on force la géographie EEE pour pouvoir vérifier
        // que le formulaire s'affiche correctement.
        let debugSettings = UMPDebugSettings()
        debugSettings.geography = .EEA
        params.debugSettings = debugSettings
        #endif

        await withCheckedContinuation { continuation in
            UMPConsentInformation.sharedInstance
                .requestConsentInfoUpdate(with: params) { error in
                    if let error { print("UMP requestConsentInfoUpdate:", error) }
                    continuation.resume()
                }
        }

        guard let root = Self.rootViewController else { return }
        await withCheckedContinuation { continuation in
            UMPConsentForm.loadAndPresentIfRequired(from: root) { error in
                if let error { print("UMP loadAndPresentIfRequired:", error) }
                continuation.resume()
            }
        }
    }

    /// Popup ATT (accès à l'IDFA). Présenté APRÈS le formulaire UMP,
    /// comme l'exige Google.
    private func requestTrackingAuthorizationIfNeeded() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        // Laisse l'UI se stabiliser, sinon le popup peut ne pas s'afficher.
        try? await Task.sleep(nanoseconds: 500_000_000)
        _ = await ATTrackingManager.requestTrackingAuthorization()
    }

    /// Vrai si l'utilisateur a accepté le suivi ET le consentement publicitaire.
    private var personalizedAllowed: Bool {
        ATTrackingManager.trackingAuthorizationStatus == .authorized
    }

    // MARK: Chargement

    /// Précharge l'interstitiel suivant. Un interstitiel ne sert qu'une fois.
    private func preload() async {
        guard AdConfig.enabled, interstitial == nil, !loading else { return }
        guard UMPConsentInformation.sharedInstance.canRequestAds else { return }
        loading = true
        defer { loading = false }

        let request = GADRequest()
        if !personalizedAllowed {
            // npa=1 : annonces non personnalisées
            let extras = GADExtras()
            extras.additionalParameters = ["npa": "1"]
            request.register(extras)
        }

        do {
            interstitial = try await GADInterstitialAd.load(
                withAdUnitID: AdConfig.interstitialUnitID, request: request)
            interstitial?.fullScreenContentDelegate = self
        } catch {
            print("AdMob load:", error)
            interstitial = nil
        }
    }

    // MARK: Décision

    /// Affiche peut-être une pub pour ce moment.
    @discardableResult
    func maybeShow(_ trigger: AdTrigger) -> Bool {
        guard eligible() else { return false }
        guard Double.random(in: 0..<1) < trigger.probability else { return false }
        return show()
    }

    /// Tous les garde-fous, hors tirage aléatoire.
    func eligible() -> Bool {
        guard AdConfig.enabled, !showing else { return false }
        guard Date().timeIntervalSince(launchedAt) >= AdConfig.grace else { return false }
        guard todayCount() < AdConfig.maxPerDay else { return false }
        guard Date().timeIntervalSince(lastShown) >= AdConfig.cooldown else { return false }
        return true
    }

    /// Présente l'interstitiel préchargé. Si rien n'est prêt (pas
    /// d'inventaire, réseau coupé), on ne montre rien et on recharge —
    /// jamais d'écran vide à la place.
    @discardableResult
    private func show() -> Bool {
        guard let ad = interstitial, let root = Self.rootViewController else {
            Task { await preload() }
            return false
        }
        showing = true
        lastShown = Date()
        bumpTodayCount()
        ad.present(fromRootViewController: root)
        return true
    }

    // MARK: Compteurs

    private var lastShown: Date {
        get { Date(timeIntervalSince1970: defaults.double(forKey: Keys.last)) }
        set { defaults.set(newValue.timeIntervalSince1970, forKey: Keys.last) }
    }

    private func todayCount() -> Int {
        guard defaults.string(forKey: Keys.day) == DateHelper.today else { return 0 }
        return defaults.integer(forKey: Keys.count)
    }

    private func bumpTodayCount() {
        defaults.set(DateHelper.today, forKey: Keys.day)
        defaults.set(todayCount() + 1, forKey: Keys.count)
    }

    /// Remet les compteurs à zéro (utile en test).
    func resetFrequencyCaps() {
        [Keys.last, Keys.count, Keys.day].forEach(defaults.removeObject(forKey:))
    }

    // MARK: Utilitaire

    /// Contrôleur racine pour présenter l'annonce.
    private static var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}

// MARK: - Cycle de vie de l'annonce

extension AdManager: GADFullScreenContentDelegate {

    nonisolated func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        Task { @MainActor in
            showing = false
            interstitial = nil
            await preload()          // on prépare déjà la suivante
        }
    }

    nonisolated func ad(_ ad: GADFullScreenPresentingAd,
                        didFailToPresentFullScreenContentWithError error: Error) {
        print("AdMob present:", error)
        Task { @MainActor in
            showing = false
            interstitial = nil
            await preload()
        }
    }
}
