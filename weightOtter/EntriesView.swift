//
//  EntriesView.swift
//  Onglet Liste : ajout d'une pesée + historique + projections.
//

import SwiftUI

struct EntriesView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var loc: Localizer

    @State private var weight = ""
    @State private var waist = ""
    @State private var hip = ""
    @State private var date = DateHelper.today
    @State private var goalTarget = ""
    @State private var goalResult = ""

    private var profile: Profile { store.profile ?? Profile(id: UUID(), username: "") }
    private var isFemale: Bool { (store.profile?.sex ?? "m") == "f" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    addForm
                    projections
                    history
                }
                .padding(16)
            }
            .background(Color.woBg.ignoresSafeArea())
            .dismissKeyboardOnTap()
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(loc.t("nav.entries"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    OtterMascot(size: 30)
                }
            }
        }
    }

    // MARK: Formulaire

    private var addForm: some View {
        VStack(spacing: 10) {
            sectionTitle(loc.t("entry.new"))

            DatePicker(loc.t("entry.date"), selection: Binding(
                get: { DateHelper.date(from: date) ?? Date() },
                set: { date = DateHelper.dateString($0) }
            ), displayedComponents: .date)
            .font(.system(size: 13, design: .monospaced))
            .foregroundColor(.woText2)

            field(loc.t("entry.weight"), text: $weight, keyboard: .decimalPad)
            field(loc.t("entry.waist"), text: $waist, keyboard: .decimalPad)
            if isFemale {
                field(loc.t("entry.hip"), text: $hip, keyboard: .decimalPad)
            }

            Button {
                Task { await add() }
            } label: {
                Text(loc.t("entry.add"))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .frame(maxWidth: .infinity)
                    .padding(11)
                    .background(Color.woBlue3)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(14)
        .cardStyle()
    }

    // MARK: Projections

    @ViewBuilder private var projections: some View {
        if store.entries.count >= 3 {
            VStack(spacing: 14) {
                VStack(spacing: 8) {
                    sectionTitle(loc.t("proj.future"))
                    projRow(loc.t("proj.7d"), 7)
                    projRow(loc.t("proj.1m"), 30)
                    projRow(loc.t("proj.3m"), 91)
                    projRow(loc.t("proj.xmas"),
                            DateHelper.daysUntil(DateHelper.nextOccurrence(month: 12, day: 25)))
                    projRow(loc.t("proj.july"),
                            DateHelper.daysUntil(DateHelper.nextOccurrence(month: 7, day: 1)))

                    if anyProjectionCapped {
                        Text(String(format: loc.t("proj.capped"),
                                    Calc.minHealthyWeight(profile: profile)))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.woText2)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 4)
                    }
                }
                .padding(14)
                .cardStyle()

                goalCard
            }
        }
    }

    /// Vrai si au moins un jalon affiché a dû être borné.
    private var anyProjectionCapped: Bool {
        let floor = Calc.minHealthyWeight(profile: profile)
        let horizons = [7, 30, 91,
                        DateHelper.daysUntil(DateHelper.nextOccurrence(month: 12, day: 25)),
                        DateHelper.daysUntil(DateHelper.nextOccurrence(month: 7, day: 1))]
        return horizons.contains { d in
            (Calc.projectWeightRaw(entries: store.entries, daysFromNow: d) ?? floor) < floor
        }
    }

    private func projRow(_ label: String, _ days: Int) -> some View {
        let raw = Calc.projectWeightRaw(entries: store.entries, daysFromNow: days)
        let floor = Calc.minHealthyWeight(profile: profile)
        let capped = raw.map { $0 < floor } ?? false
        return HStack {
            Text(label)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.woText)
            Spacer()
            if let raw {
                // Jamais de projection sous le seuil de maigreur : on affiche
                // « ≥ plancher » plutôt qu'un chiffre irréaliste.
                Text(String(format: capped ? "≥ %.1f kg" : "%.1f kg", max(raw, floor)))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(capped ? .woText2 : .woBlue)
            }
        }
    }

    // MARK: Calculateur d'objectif

    private var goalCard: some View {
        VStack(spacing: 10) {
            sectionTitle(loc.t("proj.goal.title"))
            HStack(spacing: 8) {
                TextField(loc.t("proj.goal.ph"), text: $goalTarget)
                    .keyboardType(.decimalPad)
                    .padding(9)
                    .background(Color.woBg)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.woBorder))
                    .foregroundColor(.woText)
                Button {
                    computeGoal()
                } label: {
                    Text(loc.t("proj.goal.btn"))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.woBlue3)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            if !goalResult.isEmpty {
                Text(goalResult)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.woBlue)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .cardStyle()
    }

    private func computeGoal() {
        let normalized = goalTarget.replacingOccurrences(of: ",", with: ".")
        guard let target = Double(normalized), target > 0 else {
            goalResult = ""
            return
        }
        let sorted = store.entries.sorted { $0.date < $1.date }
        guard let current = sorted.last?.w else { return }

        // Garde-fou santé : on ne planifie pas une descente sous le seuil
        // de maigreur pour la taille déclarée.
        let floor = Calc.minHealthyWeight(profile: profile)
        if target < floor {
            goalResult = String(format: loc.t("proj.goal.toolow"), floor)
            return
        }

        if current <= target + 0.05 {
            goalResult = loc.t("proj.goal.reached")
            return
        }
        guard let days = Calc.daysUntilWeight(entries: store.entries, target: target),
              days >= 0 else {
            goalResult = loc.t("proj.goal.opp")
            return
        }
        let d = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        let dateStr = DateHelper.display(DateHelper.dateString(d))
        goalResult = "\(loc.t("proj.goal.result")) \(dateStr) — \(days) \(loc.t("proj.goal.days"))"
    }

    // MARK: Historique

    private var history: some View {
        VStack(spacing: 8) {
            sectionTitle(loc.t("entry.history"))
            if store.entries.isEmpty {
                Text(loc.t("entry.empty"))
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.woText2)
                    .padding(.vertical, 20)
            } else {
                CollapsibleList(items: Array(store.entries.reversed()),
                                date: { $0.date }, spacing: 8) { e in
                    entryRow(e)
                }
            }
        }
    }

    private func entryRow(_ e: Entry) -> some View {
        let bf = Calc.bf(weight: e.w, profile: entryProfile(e, profile))
        return HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(DateHelper.display(e.date))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.woText2)
                if let bf {
                    Text(String(format: "BF: %.1f%%", bf))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.woText2)
                }
            }
            Spacer()
            Text(String(format: "%.1f kg", e.w))
                .font(.system(size: 17, weight: .bold, design: .monospaced))
                .foregroundColor(.woText)
            Button {
                Task { await store.deleteEntry(e) }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11))
                    .foregroundColor(.woText2)
            }
            .padding(.leading, 8)
        }
        .padding(12)
        .cardStyle()
    }

    // MARK: Helpers

    private func field(_ label: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.woText2)
            TextField("", text: text)
                .keyboardType(keyboard)
                .padding(9)
                .background(Color.woBg)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.woBorder))
                .foregroundColor(.woText)
        }
    }

    private func sectionTitle(_ s: String) -> some View {
        HStack {
            Text(s)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.woBlue3)
            Spacer()
        }
    }

    private func add() async {
        guard let w = Double(weight.replacingOccurrences(of: ",", with: ".")) else { return }

        // Une faute de frappe (852 au lieu de 85,2) fausserait durablement
        // toutes les régressions : on refuse les valeurs hors du plausible.
        guard w > 20, w <= 400 else {
            store.otterMessage = loc.t("entry.range")
            return
        }

        // Jour déjà renseigné → la loutre prévient dans sa bulle
        if store.entries.contains(where: { $0.date == date }) {
            store.otterMessage = loc.t("entry.exists")
            return
        }

        let ok = await store.addEntry(
            date: date,
            w: w,
            cal: nil,
            waist: Double(waist.replacingOccurrences(of: ",", with: ".")),
            hip: isFemale ? Double(hip.replacingOccurrences(of: ",", with: ".")) : nil
        )
        if ok {
            weight = ""; waist = ""; hip = ""
            date = DateHelper.today
            AdManager.shared.maybeShow(.weighIn)
        }
    }
}
