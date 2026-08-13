//
//  Calculations.swift
//  Estimations APPROXIMATIVES, à but purement indicatif.
//

import Foundation

enum Calc {

    /// % masse grasse — Navy, sinon Lean et al., sinon Deurenberg (IMC).
    static func bf(weight: Double, profile: Profile) -> Double? {
        guard let h = profile.h, h > 0 else { return nil }
        let sex   = profile.sex ?? "m"
        let waist = profile.waist ?? 0
        let neck  = profile.neck ?? 0
        let hip   = profile.hip ?? 0

        // 1. Méthode Navy
        if waist > 0, neck > 0, waist > neck {
            if sex == "m" {
                let v = 495 / (1.0324 - 0.19077 * log10(waist - neck)
                               + 0.15456 * log10(h)) - 450
                return clamp(v)
            }
            if sex == "f", hip > 0 {
                let v = 495 / (1.29579 - 0.35004 * log10(waist + hip - neck)
                               + 0.22100 * log10(h)) - 450
                return clamp(v)
            }
        }

        // 2. Tour de taille seul (Lean et al. 1996)
        if waist > 0 {
            let v: Double
            if sex == "m" {
                v = 0.567 * waist - 0.211 * h + 4.75
            } else if hip > 0 {
                v = 0.600 * waist + 0.100 * hip - 0.150 * h - 0.25
            } else {
                v = 0.600 * waist - 0.150 * h + 9.75
            }
            return clamp(v)
        }

        // 3. Fallback IMC (Deurenberg)
        guard let age = profile.age else { return nil }
        let bmi = weight / pow(h / 100, 2)
        let sexFac = sex == "m" ? 1.0 : 0.0
        return clamp(1.20 * bmi + 0.23 * Double(age) - 10.8 * sexFac - 5.4)
    }

    static func leanMass(weight: Double, profile: Profile) -> Double? {
        guard let bf = bf(weight: weight, profile: profile) else { return nil }
        return weight * (1 - bf / 100)
    }

    /// BMR (Mifflin-St Jeor)
    static func bmr(weight: Double, profile: Profile) -> Double? {
        guard let h = profile.h, let age = profile.age else { return nil }
        let sex = profile.sex ?? "m"
        return sex == "m"
            ? 10 * weight + 6.25 * h - 5 * Double(age) + 5
            : 10 * weight + 6.25 * h - 5 * Double(age) - 161
    }

    /// TDEE = BMR × activité
    static func tdee(weight: Double, profile: Profile) -> Double? {
        guard let b = bmr(weight: weight, profile: profile) else { return nil }
        return b * (profile.act ?? 1.55)
    }

    /// Régression linéaire (moindres carrés) sur x/y explicites.
    static func linReg(xs: [Double], ys: [Double]) -> (slope: Double, intercept: Double)? {
        let n = xs.count
        guard n >= 3, ys.count == n else { return nil }
        let mX = xs.reduce(0, +) / Double(n)
        let mY = ys.reduce(0, +) / Double(n)
        var num = 0.0, den = 0.0
        for i in 0..<n {
            num += (xs[i] - mX) * (ys[i] - mY)
            den += (xs[i] - mX) * (xs[i] - mX)
        }
        guard den != 0 else { return nil }
        let slope = num / den
        return (slope, mY - slope * mX)
    }

    /// Poids plancher physiologique : bas de la fourchette d'IMC normal (18,5).
    /// Une droite de régression prolongée sur un an finit sinon par annoncer
    /// des poids impossibles — inacceptable dans une app de santé.
    /// 40 kg par défaut si la taille est inconnue.
    static func minHealthyWeight(profile: Profile) -> Double {
        guard let h = profile.h, h >= 100 else { return 40 }
        return 18.5 * pow(h / 100, 2)
    }

    /// Projection brute de la régression, sans garde-fou.
    static func projectWeightRaw(entries: [Entry], daysFromNow: Int) -> Double? {
        guard entries.count >= 3 else { return nil }
        let sorted = entries.sorted { $0.date < $1.date }
        guard let first = sorted.first?.date else { return nil }
        let xs = sorted.map { Double(DateHelper.days(from: first, to: $0.date)) }
        let ys = sorted.map { $0.w }
        guard let reg = linReg(xs: xs, ys: ys) else { return nil }
        let todayX = Double(DateHelper.days(from: first, to: DateHelper.today))
        return reg.slope * (todayX + Double(daysFromNow)) + reg.intercept
    }

    /// Projette le poids à N jours, borné au plancher physiologique.
    static func projectWeight(entries: [Entry], daysFromNow: Int,
                              profile: Profile? = nil) -> Double? {
        guard let raw = projectWeightRaw(entries: entries, daysFromNow: daysFromNow)
        else { return nil }
        guard let p = profile else { return raw }
        return max(raw, minHealthyWeight(profile: p))
    }

    /// Nombre de jours depuis aujourd'hui avant d'atteindre `target`
    /// selon la tendance linéaire. nil si impossible (pente nulle / < 3 points).
    static func daysUntilWeight(entries: [Entry], target: Double) -> Int? {
        guard entries.count >= 3 else { return nil }
        let sorted = entries.sorted { $0.date < $1.date }
        guard let first = sorted.first?.date else { return nil }
        let xs = sorted.map { Double(DateHelper.days(from: first, to: $0.date)) }
        let ys = sorted.map { $0.w }
        guard let reg = linReg(xs: xs, ys: ys), reg.slope != 0 else { return nil }
        let targetX = (target - reg.intercept) / reg.slope
        let todayX = Double(DateHelper.days(from: first, to: DateHelper.today))
        return Int((targetX - todayX).rounded())
    }

    private static func clamp(_ v: Double) -> Double { min(60, max(3, v)) }
}

/// Fusionne les mesures d'une pesée avec le profil (la pesée prime).
func entryProfile(_ entry: Entry, _ profile: Profile) -> Profile {
    var p = profile
    if let w = entry.waist { p.waist = w }
    if let h = entry.hip   { p.hip = h }
    return p
}
