//
//  SummaryView.swift
//  Onglet Résumé : grille de statistiques (poids, déficit, projections…).
//

import SwiftUI

struct SummaryView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var loc: Localizer

    private let kcalPerKg = 7700.0

    var body: some View {
        NavigationStack {
            ScrollView {
                if store.entries.isEmpty {
                    Text(loc.t("sum.empty"))
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.woText2)
                        .multilineTextAlignment(.center)
                        .padding(.top, 60)
                        .padding(.horizontal, 30)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10),
                                        GridItem(.flexible(), spacing: 10)],
                              spacing: 10) {
                        ForEach(stats) { s in
                            StatCard(label: s.label, value: s.value,
                                     color: s.color, subtitle: s.subtitle)
                        }
                    }
                    .padding(16)
                }
            }
            .background(Color.woBg.ignoresSafeArea())
            .navigationTitle(loc.t("nav.summary"))
        }
    }

    // MARK: Données

    private struct Stat: Identifiable {
        let id = UUID()
        let label: String
        let value: String
        var color: Color = .woBlue
        var subtitle: String? = nil
    }

    private var stats: [Stat] {
        let es = store.entries.sorted { $0.date < $1.date }
        guard let first = es.first, let last = es.last else { return [] }
        let profile = store.profile ?? Profile(id: UUID(), username: "")
        var out: [Stat] = []

        out.append(Stat(label: loc.t("sum.initial"), value: kg(first.w)))
        out.append(Stat(label: loc.t("sum.current"), value: kg(last.w)))

        let totalLost = first.w - last.w
        out.append(Stat(label: loc.t("sum.lost"),
                        value: signed(totalLost, 1),
                        color: lossColor(totalLost)))

        out.append(Stat(label: loc.t("sum.days"), value: "\(es.count)"))

        if es.count >= 2 {
            let span = max(1, DateHelper.days(from: first.date, to: last.date))
            let lpw = (totalLost / Double(span)) * 7
            out.append(Stat(label: loc.t("sum.perweek"),
                            value: signed(lpw, 2),
                            color: lossColor(lpw)))
        }

        if let bf = Calc.bf(weight: last.w, profile: entryProfile(last, profile)) {
            out.append(Stat(label: loc.t("sum.bf"),
                            value: String(format: "%.1f%%", bf), color: .woPurple))
            out.append(Stat(label: loc.t("sum.lean"), value: kg(last.w * (1 - bf / 100))))
        }

        if let tdee = Calc.tdee(weight: last.w, profile: profile) {
            out.append(Stat(label: loc.t("sum.tdee"), value: "\(Int(tdee)) kcal/j"))
        }

        // Déficit calorique — fusion des deux sources de calories
        // (écran Track + calories historiques saisies avec le poids)
        let defs = dailyDeficits(entries: es, profile: profile)
        if !defs.isEmpty {
            let total = defs.reduce(0, +)
            let avg = total / Double(defs.count)
            out.append(Stat(label: loc.t("sum.avgdef"),
                            value: "\(Int(avg)) kcal",
                            color: avg > 0 ? .woGreen : .woRed,
                            subtitle: "\(defs.count) \(loc.t("sum.loggeddays"))"))
            out.append(Stat(label: loc.t("sum.totdef"),
                            value: "\(Int(total)) kcal",
                            color: total > 0 ? .woGreen : .woRed,
                            subtitle: "≈ \(String(format: "%.2f", total / kcalPerKg)) kg \(loc.t("sum.fattheo"))"))
        }

        if let p30 = Calc.projectWeight(entries: store.entries, daysFromNow: 30) {
            out.append(Stat(label: loc.t("sum.proj30"),
                            value: kg(p30),
                            color: p30 < last.w ? .woGreen : .woRed))
        }

        if let goal = profile.goal, goal > 0,
           let dtg = Calc.daysUntilWeight(entries: store.entries, target: goal), dtg > 0 {
            out.append(Stat(label: loc.t("sum.goalin"),
                            value: "\(dtg) \(loc.t("sum.daysunit"))",
                            color: .woPurple,
                            subtitle: "\(loc.t("sum.target")) \(kg(goal))"))
        }

        return out
    }

    // MARK: Déficit calorique (sources fusionnées)

    /// Déficit (TDEE − calories) pour chaque jour où des calories ont été
    /// enregistrées, quelle que soit la source :
    ///   - écran Track (TrackDay.cal) — prioritaire
    ///   - calories saisies avec une pesée (Entry.cal) — repli / historique
    /// Le TDEE d'un jour est estimé avec le poids de la pesée la plus récente
    /// à cette date (ou la première pesée si le jour la précède).
    private func dailyDeficits(entries es: [Entry], profile: Profile) -> [Double] {
        guard !es.isEmpty else { return [] }

        // 1. Calories par jour : l'écran Track prime sur la valeur d'une pesée.
        var calByDate: [String: Int] = [:]
        for e in es {
            if let c = e.cal, c > 0 { calByDate[e.date] = c }
        }
        for t in store.tracks where t.cal > 0 {
            calByDate[t.date] = t.cal
        }

        // 2. Poids de référence à une date (pesées triées par date croissante).
        let weighs = es.map { (date: $0.date, w: $0.w) }
        func weight(on date: String) -> Double? {
            var chosen = weighs.first?.w
            for wgh in weighs {
                if wgh.date <= date { chosen = wgh.w } else { break }
            }
            return chosen
        }

        // 3. Déficit par jour calorique.
        var out: [Double] = []
        for (date, cal) in calByDate {
            guard let w = weight(on: date),
                  let td = Calc.tdee(weight: w, profile: profile), td > 0
            else { continue }
            out.append(td - Double(cal))
        }
        return out
    }

    // MARK: Helpers de format

    private func kg(_ v: Double) -> String {
        v == v.rounded() ? "\(Int(v)) kg" : String(format: "%.1f kg", v)
    }

    private func signed(_ v: Double, _ decimals: Int) -> String {
        let sign = v > 0 ? "−" : (v < 0 ? "+" : "")
        return "\(sign)\(String(format: "%.\(decimals)f", abs(v))) kg"
    }

    private func lossColor(_ v: Double) -> Color {
        v > 0 ? .woGreen : (v < 0 ? .woRed : .woText2)
    }
}

// MARK: - Carte statistique

struct StatCard: View {
    let label: String
    let value: String
    var color: Color = .woBlue
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.woText2)
                .multilineTextAlignment(.center)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .multilineTextAlignment(.center)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.woText2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(Color.woCard)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.woBorder))
        .cornerRadius(8)
    }
}
