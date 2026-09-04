//
//  TrackView.swift
//  Onglet Track : compteurs CRT calories / protéines + carnet de bord.
//

import SwiftUI

struct TrackView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var loc: Localizer
    @State private var digicode: DigicodeTarget?
    @State private var selectedDate = DateHelper.today

    /// Moment publicitaire mérité, en attente que le digicode ait fini de se
    /// fermer. Voir `firePendingAd()`.
    @State private var pendingAd: AdTrigger?

    private var isToday: Bool { selectedDate == DateHelper.today }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    dateNavigator

                    HStack(spacing: 12) {
                        counter(label: loc.t("track.cal"),
                                value: store.track(for: selectedDate)?.cal ?? 0,
                                unit: "kcal", field: .cal)
                        counter(label: loc.t("track.protein"),
                                value: store.track(for: selectedDate)?.protein ?? 0,
                                unit: "g", field: .protein)
                    }

                    logbook
                }
                .padding(16)
            }
            .background(Color.woBg.ignoresSafeArea())
            .navigationTitle(loc.t("nav.track"))
        }
        .sheet(item: $digicode, onDismiss: firePendingAd) { target in
            DigicodeSheet(target: target) { value in
                Task {
                    await store.setTrack(field: target.field,
                                         value: value, date: target.date)
                    guard store.opError == nil else { return }

                    // On ne présente pas la pub d'ici : le digicode est encore
                    // à l'écran, et UIKit refuse d'afficher un interstitiel
                    // par-dessus une feuille en cours de fermeture. On note le
                    // moment mérité, `onDismiss` le déclenchera.
                    pendingAd = target.field == .cal ? .calorie : .protein
                    if digicode == nil { firePendingAd() }   // déjà refermé
                }
            }
            .environmentObject(loc)
        }
    }

    /// Affiche la pub en attente, une fois le digicode réellement refermé.
    /// Appelé par `onDismiss`, ou par la sauvegarde si elle se termine après.
    /// Le `pendingAd` est vidé d'abord : impossible de la jouer deux fois.
    private func firePendingAd() {
        guard let trigger = pendingAd else { return }
        pendingAd = nil
        Task {
            // Laisser l'animation de fermeture se terminer, sinon le
            // contrôleur au premier plan est encore la feuille.
            try? await Task.sleep(nanoseconds: 350_000_000)
            AdManager.shared.maybeShow(trigger)
        }
    }

    // MARK: Sélecteur de jour

    private var dateNavigator: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                navArrow("chevron.left") {
                    selectedDate = DateHelper.previous(selectedDate)
                }

                // Choix libre d'une date (jamais dans le futur)
                DatePicker("", selection: Binding(
                    get: { DateHelper.date(from: selectedDate) ?? Date() },
                    set: { selectedDate = DateHelper.dateString($0) }
                ), in: ...Date(), displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(.woGreen)

                navArrow("chevron.right") {
                    selectedDate = DateHelper.next(selectedDate)
                }
                .disabled(isToday)
                .opacity(isToday ? 0.25 : 1)
            }

            if isToday {
                Text(loc.t("track.today"))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.woGreen)
            } else {
                Button {
                    selectedDate = DateHelper.today
                } label: {
                    Text(loc.t("track.backtoday"))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.woGreen)
                }
            }
        }
        .padding(.bottom, 2)
    }

    private func navArrow(_ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.woGreen)
                .frame(width: 40, height: 36)
                .background(Color.woGreen.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.woGreen.opacity(0.4)))
                .cornerRadius(8)
        }
    }

    // MARK: Compteur CRT

    private func counter(label: String, value: Int, unit: String,
                         field: TrackField) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 14, design: .monospaced)).italic()
                .foregroundColor(.woGreen)
            Text("\(value)")
                .font(.system(size: 40, weight: .bold, design: .monospaced))
                .foregroundColor(.woGreen)
                .onTapGesture {
                    digicode = DigicodeTarget(field: field, date: selectedDate,
                                              label: label, unit: unit,
                                              mode: .set, current: value)
                }
            Text(unit)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.woGreen.opacity(0.6))
            HStack(spacing: 8) {
                crtButton("−") {
                    digicode = DigicodeTarget(field: field, date: selectedDate,
                                              label: label, unit: unit,
                                              mode: .subtract, current: value)
                }
                crtButton("+") {
                    digicode = DigicodeTarget(field: field, date: selectedDate,
                                              label: label, unit: unit,
                                              mode: .add, current: value)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(Color.woGreen.opacity(0.06))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.woGreen.opacity(0.35), lineWidth: 2))
        .cornerRadius(12)
    }

    private func crtButton(_ s: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(s)
                .font(.system(size: 20, design: .monospaced))
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(Color.woGreen.opacity(0.08))
                .foregroundColor(.woGreen)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.woGreen.opacity(0.4)))
                .cornerRadius(8)
        }
    }

    // MARK: Carnet de bord

    private var logbook: some View {
        VStack(spacing: 8) {
            Text(loc.t("track.logbook"))
                .font(.system(size: 14, design: .monospaced)).italic()
                .foregroundColor(.woGreen)

            let past = store.tracks
                .filter { $0.date != selectedDate }
                .sorted { $0.date > $1.date }

            if past.isEmpty {
                Text(loc.t("track.empty"))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.woGreen.opacity(0.55))
                    .padding(.vertical, 16)
            } else {
                CollapsibleList(items: past, date: { $0.date },
                                spacing: 8, tint: .woGreen) { r in
                    logbookRow(r)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(Color.woGreen.opacity(0.06))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.woGreen.opacity(0.35), lineWidth: 2))
        .cornerRadius(12)
    }

    private func logbookRow(_ r: TrackDay) -> some View {
        HStack {
            Button {
                Task { await store.deleteTrack(date: r.date) }
            } label: {
                Image(systemName: "xmark").font(.system(size: 11))
                    .foregroundColor(.woGreen.opacity(0.5))
            }
            // Toucher la date ramène le compteur sur ce jour
            Text(DateHelper.display(r.date))
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.woGreen.opacity(0.7))
                .underline()
                .onTapGesture { selectedDate = r.date }
            Spacer()
            Text("\(r.cal) kcal")
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(.woGreen)
                .onTapGesture {
                    digicode = DigicodeTarget(field: .cal, date: r.date,
                                              label: loc.t("track.cal"), unit: "kcal",
                                              mode: .set, current: r.cal)
                }
            Spacer()
            Text("\(r.protein) g")
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.woGreen.opacity(0.85))
                .onTapGesture {
                    digicode = DigicodeTarget(field: .protein, date: r.date,
                                              label: loc.t("track.protein"), unit: "g",
                                              mode: .set, current: r.protein)
                }
        }
        .padding(10)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.woGreen.opacity(0.22)))
    }
}

// MARK: - Digicode

struct DigicodeTarget: Identifiable {
    /// set = saisie directe · add = ajout au total · subtract = retrait du total
    enum Mode { case set, add, subtract }

    let id = UUID()
    let field: TrackField
    let date: String
    let label: String
    var unit: String = ""
    var mode: Mode = .set
    var current: Int = 0
}

struct DigicodeSheet: View {
    let target: DigicodeTarget
    var onConfirm: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var loc: Localizer
    @State private var buffer = ""

    private let keys = ["1","2","3","4","5","6","7","8","9","⌫","0","OK"]

    private var entered: Int { Int(buffer) ?? 0 }

    /// Valeur absolue finale selon le mode.
    private var resultValue: Int {
        switch target.mode {
        case .set:      return entered
        case .add:      return target.current + entered
        case .subtract: return max(0, target.current - entered)
        }
    }

    private var isSubtract: Bool { target.mode == .subtract }
    private var opColor: Color { isSubtract ? .woRed : .woGreen }

    var body: some View {
        ZStack {
            Color.woBg.ignoresSafeArea()
            VStack(spacing: 14) {
                // Barre supérieure : bouton retour (conserve la valeur enregistrée)
                HStack {
                    Button { dismiss() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text(loc.t("digi.back"))
                        }
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.woGreen)
                    }
                    Spacer()
                }

                Text(target.date == DateHelper.today
                     ? target.label
                     : "\(target.label) · \(DateHelper.display(target.date))")
                    .font(.system(size: 15, design: .monospaced)).italic()
                    .foregroundColor(.woGreen)

                // Indicateur d'opération (modes ajout / retrait)
                if target.mode != .set {
                    VStack(spacing: 3) {
                        Text("\(loc.t(isSubtract ? "digi.sub.hint" : "digi.add.hint")) \(entered) \(target.unit)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(opColor)
                        Text(target.label)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.woText2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(opColor.opacity(0.1))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(opColor.opacity(0.4)))
                    .cornerRadius(8)
                }

                Text(buffer.isEmpty ? "0" : buffer)
                    .font(.system(size: 38, weight: .bold, design: .monospaced))
                    .foregroundColor(.woGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.4))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.woGreen.opacity(0.3)))

                // Rappel du total actuellement enregistré (+ nouveau total si opération)
                VStack(spacing: 4) {
                    Text("\(loc.t("digi.current")) : \(target.current) \(target.unit)")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.woGreen.opacity(0.8))
                    if target.mode != .set {
                        Text("\(loc.t("digi.newtotal")) : \(resultValue) \(target.unit)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.woGreen)
                    }
                }

                LazyVGrid(columns: Array(repeating: GridItem(spacing: 8), count: 3), spacing: 8) {
                    ForEach(keys, id: \.self) { k in
                        Button { tap(k) } label: {
                            Text(k)
                                .font(.system(size: 20, design: .monospaced))
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .background(k == "OK" ? Color.woGreen.opacity(0.5)
                                                      : Color.woGreen.opacity(0.08))
                                .foregroundColor(k == "OK" ? .black : .woGreen)
                                .overlay(RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.woGreen.opacity(0.35)))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(20)
        }
        .onAppear {
            // En saisie directe, on pré-remplit avec la valeur déjà enregistrée.
            if target.mode == .set, target.current > 0 {
                buffer = String(target.current)
            }
        }
    }

    private func tap(_ k: String) {
        switch k {
        case "⌫": if !buffer.isEmpty { buffer.removeLast() }
        case "OK":
            // Saisie directe vidée → on ne touche pas à la valeur enregistrée.
            if target.mode == .set, buffer.isEmpty {
                dismiss(); return
            }
            onConfirm(resultValue)
            dismiss()
        default:
            if buffer.count < 5 { buffer += k }
        }
    }
}
