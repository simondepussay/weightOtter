//
//  ProfileView.swift
//  Onglet Profil : infos, mesures, composition corporelle, langue, déconnexion.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var loc: Localizer

    @State private var age = ""
    @State private var height = ""
    @State private var sex = "m"
    @State private var act = 1.55
    @State private var goal = ""
    @State private var neck = ""
    @State private var showActivityTip = false
    @State private var showDeleteConfirm = false
    @State private var deleting = false
    @State private var deleteFailed = false

    // (clé d'activité, multiplicateur)
    private let activities: [(String, Double)] = [
        ("act.sed", 1.2), ("act.light", 1.375), ("act.mod", 1.55),
        ("act.active", 1.725), ("act.very", 1.9)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    accountSection
                    infoSection
                    measuresSection
                    bodySection
                    langSection

                    Button {
                        Task { await save() }
                    } label: {
                        Text(loc.t("prof.save"))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .frame(maxWidth: .infinity).padding(12)
                            .background(Color.woBlue3).foregroundColor(.white)
                            .cornerRadius(8)
                    }

                    Button {
                        Task { await store.signOut() }
                    } label: {
                        Text(loc.t("prof.logout"))
                            .font(.system(size: 13, design: .monospaced))
                            .frame(maxWidth: .infinity).padding(12)
                            .background(Color.woRed.opacity(0.12))
                            .foregroundColor(.woRed)
                            .overlay(RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.woRed.opacity(0.3)))
                            .cornerRadius(8)
                    }

                    Button {
                        showDeleteConfirm = true
                    } label: {
                        HStack(spacing: 6) {
                            if deleting { ProgressView().tint(.woRed) }
                            Text(loc.t("prof.delete"))
                        }
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .frame(maxWidth: .infinity).padding(12)
                        .foregroundColor(.woRed)
                    }
                    .disabled(deleting)

                    DisclaimerFooter()
                }
                .padding(16)
            }
            .background(Color.woBg.ignoresSafeArea())
            .dismissKeyboardOnTap()
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(loc.t("nav.profile"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HelpButton(username: store.username)
                }
            }
            .onAppear(perform: load)
            .alert(loc.t("prof.delete.title"), isPresented: $showDeleteConfirm) {
                Button(loc.t("prof.cancel"), role: .cancel) { }
                Button(loc.t("prof.delete.confirm"), role: .destructive) {
                    Task {
                        deleting = true
                        let ok = await store.deleteAccount()
                        deleting = false
                        if !ok { deleteFailed = true }
                    }
                }
            } message: {
                Text(loc.t("prof.delete.msg"))
            }
            .alert(loc.t("prof.delete.error"), isPresented: $deleteFailed) {
                Button("OK", role: .cancel) { }
            }
        }
    }

    // MARK: Sections

    /// Rappel du compte connecté. Le PIN n'apparaît pas : Supabase n'en
    /// conserve qu'une empreinte, l'app ne peut pas le relire.
    private var accountSection: some View {
        VStack(spacing: 10) {
            title(loc.t("prof.account"))
            calcRow(loc.t("prof.username"), store.username ?? "--")

            Link(destination: AppLinks.privacyPolicy) {
                HStack(spacing: 6) {
                    Text(loc.t("prof.privacy"))
                    Image(systemName: "arrow.up.right.square")
                }
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.woBlue)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 2)
            }
        }
        .padding(14).cardStyle()
    }

    private var infoSection: some View {
        VStack(spacing: 10) {
            title(loc.t("prof.info"))
            field(loc.t("prof.age"), $age, .numberPad)
            field(loc.t("prof.height"), $height, .numberPad)

            VStack(alignment: .leading, spacing: 4) {
                label(loc.t("prof.sex"))
                Picker("", selection: $sex) {
                    Text(loc.t("prof.sex.m")).tag("m")
                    Text(loc.t("prof.sex.f")).tag("f")
                }.pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    label(loc.t("prof.activity"))
                    Button {
                        withAnimation { showActivityTip.toggle() }
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 14))
                            .foregroundColor(.woBlue)
                    }
                    Spacer()
                }
                if showActivityTip {
                    VStack(alignment: .leading, spacing: 7) {
                        activityTip("act.sed", "acttip.sed")
                        activityTip("act.light", "acttip.light")
                        activityTip("act.mod", "acttip.mod")
                        activityTip("act.active", "acttip.active")
                        activityTip("act.very", "acttip.very")
                    }
                    .padding(10)
                    .background(Color.woBg)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.woBorder))
                    .cornerRadius(8)
                }
                Picker("", selection: $act) {
                    ForEach(activities, id: \.1) { Text(loc.t($0.0)).tag($0.1) }
                }.pickerStyle(.menu).tint(.woBlue)
            }
            field(loc.t("prof.goal"), $goal, .decimalPad)
        }
        .padding(14).cardStyle()
    }

    private var measuresSection: some View {
        VStack(spacing: 10) {
            title(loc.t("prof.measures"))
            field(loc.t("prof.neck"), $neck, .decimalPad)

            // Le tour de taille (et de hanches) provient de la dernière pesée,
            // il ne se saisit plus ici. Rappel de la valeur reprise.
            if let w = lastWaist {
                calcRow(loc.t("prof.waist.last"), String(format: "%.1f cm", w))
            }
            if sex == "f", let h = lastHip {
                calcRow(loc.t("prof.hip.last"), String(format: "%.1f cm", h))
            }

            Text(loc.t("prof.measures.hint"))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.woText2)
        }
        .padding(14).cardStyle()
    }

    private var bodySection: some View {
        VStack(spacing: 8) {
            title(loc.t("prof.body"))
            let p = currentProfile()
            let w = store.entries.last?.w
            calcRow(loc.t("prof.bf"), w.flatMap { Calc.bf(weight: $0, profile: p) }
                .map { String(format: "%.1f %%", $0) })
            calcRow(loc.t("prof.lean"), w.flatMap { Calc.leanMass(weight: $0, profile: p) }
                .map { String(format: "%.1f kg", $0) })
            calcRow(loc.t("prof.bmr"), w.flatMap { Calc.bmr(weight: $0, profile: p) }
                .map { "\(Int($0)) kcal/j" })
            calcRow(loc.t("prof.tdee"), w.flatMap { Calc.tdee(weight: $0, profile: p) }
                .map { "\(Int($0)) kcal/j" })
        }
        .padding(14).cardStyle()
    }

    private var langSection: some View {
        VStack(spacing: 10) {
            title(loc.t("prof.lang"))
            Picker("", selection: $loc.lang) {
                ForEach(AppLang.allCases) { l in
                    Text(l.label).tag(l)
                }
            }
            .pickerStyle(.segmented)

            Text(loc.t("prof.lang.hint"))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.woText2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14).cardStyle()
    }

    // MARK: Helpers

    private func calcRow(_ l: String, _ v: String?) -> some View {
        HStack {
            Text(l).font(.system(size: 12, design: .monospaced)).foregroundColor(.woText2)
            Spacer()
            Text(v ?? "--").font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.woBlue)
        }
        .padding(8)
        .background(Color.woBlue3.opacity(0.08))
        .cornerRadius(6)
    }

    private func field(_ l: String, _ text: Binding<String>, _ kb: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            label(l)
            TextField("", text: text)
                .keyboardType(kb)
                .padding(9)
                .background(Color.woBg)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.woBorder))
                .foregroundColor(.woText)
        }
    }

    private func label(_ s: String) -> some View {
        Text(s).font(.system(size: 11, design: .monospaced)).foregroundColor(.woText2)
    }

    /// Ligne du tooltip d'activité — `nameKey` et `descKey` sont des clés i18n.
    private func activityTip(_ nameKey: String, _ descKey: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(loc.t(nameKey))
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.woBlue)
            Text(loc.t(descKey))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.woText2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func title(_ s: String) -> some View {
        HStack {
            Text(s).font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.woBlue3)
            Spacer()
        }
    }

    private func num(_ s: String) -> Double? {
        Double(s.replacingOccurrences(of: ",", with: "."))
    }

    /// Tour de taille de la pesée la plus récente qui en contient un.
    private var lastWaist: Double? {
        store.entries.last(where: { $0.waist != nil })?.waist
    }

    /// Tour de hanches de la pesée la plus récente qui en contient un.
    private var lastHip: Double? {
        store.entries.last(where: { $0.hip != nil })?.hip
    }

    private func currentProfile() -> Profile {
        var p = store.profile ?? Profile(id: UUID(), username: "")
        p.age = Int(age); p.h = num(height); p.sex = sex; p.act = act
        p.goal = num(goal); p.neck = num(neck)
        // Tour de taille / hanches : repris de la dernière pesée (plus saisi ici).
        p.waist = lastWaist
        p.hip = sex == "f" ? lastHip : nil
        return p
    }

    private func load() {
        guard let p = store.profile else { return }
        age = p.age.map(String.init) ?? ""
        height = p.h.map { String($0) } ?? ""
        sex = p.sex ?? "m"
        act = p.act ?? 1.55
        goal = p.goal.map { String($0) } ?? ""
        neck = p.neck.map { String($0) } ?? ""
    }

    private func save() async {
        await store.saveProfile(currentProfile())
    }
}
