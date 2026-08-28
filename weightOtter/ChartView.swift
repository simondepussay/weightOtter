//
//  ChartView.swift


import SwiftUI
import Charts

struct ChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct ChartView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var loc: Localizer

    @State private var mode = 0          // 0 = poids, 1 = masse grasse, 2 = calories
    @State private var bfUnit = 0        // 0 = %, 1 = kg (mode masse grasse)
    @State private var calSmooth = false // lissage par blocs de 7 jours
    @State private var projDays = 100

    /// Taille d'un bloc de lissage, en jours.
    private let smoothingWindow = 7

    private let projOptions = [0, 10, 50, 100]

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                Picker("", selection: $mode) {
                    Text(loc.t("chart.seg.weight")).tag(0)
                    Text(loc.t("chart.seg.fat")).tag(1)
                    Text(loc.t("chart.seg.cal")).tag(2)
                }
                .pickerStyle(.segmented)

                // Choix de l'unité en mode masse grasse : % ou kg
                if mode == 1 {
                    Picker("", selection: $bfUnit) {
                        Text("%").tag(0)
                        Text("kg").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 220)
                }

                // Lissage en mode calories : les valeurs quotidiennes sautent
                // trop pour qu'une tendance soit lisible.
                if mode == 2 {
                    Picker("", selection: $calSmooth) {
                        Text(loc.t("chart.cal.daily")).tag(false)
                        Text(loc.t("chart.cal.smoothed")).tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 260)
                }

                if realPoints.count < 2 {
                    Spacer()
                    Text(loc.t("chart.nodata"))
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.woText2)
                    Spacer()
                } else {
                    chart
                    if mode == 0 { projSelector }
                    Spacer()
                }
            }
            .padding(16)
            .background(Color.woBg.ignoresSafeArea())
            .navigationTitle(loc.t("nav.chart"))
        }
    }

    // MARK: Graphe

    private var chart: some View {
        Chart {
            ForEach(realPoints) { p in
                LineMark(
                    x: .value("Date", p.date),
                    y: .value("Valeur", p.value),
                    series: .value("Série", "réel")
                )
                .foregroundStyle(accent)
                .interpolationMethod(.catmullRom)

                // Pas de points en mode calories : trop nombreux, illisible.
                if mode != 2 {
                    PointMark(
                        x: .value("Date", p.date),
                        y: .value("Valeur", p.value)
                    )
                    .foregroundStyle(accent)
                    .symbolSize(26)
                }
            }

            if mode == 0 {
                ForEach(projPoints) { p in
                    LineMark(
                        x: .value("Date", p.date),
                        y: .value("Valeur", p.value),
                        series: .value("Série", "projection")
                    )
                    .foregroundStyle(Color.woGreen)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine().foregroundStyle(Color.woBorder)
                // Swift Charts formate avec sa propre locale et ignore
                // celle de l'environnement : on la force, sinon l'axe reste
                // en français sous une interface anglaise ou japonaise.
                AxisValueLabel(format: .dateTime.day().month(.abbreviated)
                    .locale(Locale(identifier: loc.lang.rawValue)))
                    .foregroundStyle(Color.woText2)
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine().foregroundStyle(Color.woBorder)
                AxisValueLabel().foregroundStyle(Color.woText2)
            }
        }
        .chartYScale(domain: yDomain)
        .frame(height: 280)
        .padding(12)
        .cardStyle()
    }

    // MARK: Sélecteur de projection

    private var projSelector: some View {
        HStack(spacing: 8) {
            Text(loc.t("chart.proj"))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.woText2)
            ForEach(projOptions, id: \.self) { d in
                Button { projDays = d } label: {
                    Text("\(d)")
                        .font(.system(size: 12, design: .monospaced))
                        .frame(minWidth: 32)
                        .padding(.vertical, 6)
                        .background(projDays == d ? Color.woGreen : Color.clear)
                        .foregroundColor(projDays == d ? .black : .woText2)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.woBorder))
                        .cornerRadius(6)
                }
            }
        }
    }

    private var accent: Color {
        switch mode {
        case 0:  return .woBlue    // poids
        case 2:  return .woGreen   // calories
        default: return .woPurple  // masse grasse
        }
    }

    /// Échelle Y adaptée au mode :
    ///   poids → −5 / +3 kg · masse grasse → ±2 · calories → ±200 kcal.
    private var yDomain: ClosedRange<Double> {
        let vals = realPoints.map { $0.value }
        guard let lo = vals.min(), let hi = vals.max() else { return 0...100 }
        switch mode {
        case 0:  return (lo - 5)...(hi + 3)
        case 2:  return max(0, lo - 200)...(hi + 200)
        default: return max(0, lo - 2)...(hi + 2)
        }
    }

    // MARK: Données

    private var sortedEntries: [Entry] {
        store.entries.sorted { $0.date < $1.date }
    }

    /// Points réels selon le mode (poids · masse grasse · calories).
    private var realPoints: [ChartPoint] {
        if mode == 2 { return caloriePoints }

        let profile = store.profile ?? Profile(id: UUID(), username: "")
        return sortedEntries.compactMap { e -> ChartPoint? in
            guard let d = DateHelper.date(from: e.date) else { return nil }
            if mode == 0 {
                return ChartPoint(date: d, value: e.w)
            }
            guard let bf = Calc.bf(weight: e.w, profile: entryProfile(e, profile))
            else { return nil }
            // % de masse grasse, ou masse grasse en kg selon l'unité choisie
            let value = bfUnit == 0 ? bf : e.w * bf / 100
            return ChartPoint(date: d, value: value)
        }
    }

    /// Calories mangées par jour — sources fusionnées :
    /// écran Track (prioritaire) + calories historiques saisies avec le poids.
    private var caloriePoints: [ChartPoint] {
        var calByDate: [String: Int] = [:]
        for e in sortedEntries {
            if let c = e.cal, c > 0 { calByDate[e.date] = c }
        }
        for t in store.tracks where t.cal > 0 {
            calByDate[t.date] = t.cal
        }
        let daily = calByDate.compactMap { (date, cal) -> ChartPoint? in
            guard let d = DateHelper.date(from: date) else { return nil }
            return ChartPoint(date: d, value: Double(cal))
        }
        .sorted { $0.date < $1.date }

        return calSmooth ? smoothed(daily) : daily
    }

    /// Découpe la série en blocs de `smoothingWindow` jours calendaires et
    /// remplace chaque valeur par la moyenne de son bloc.
    ///
    /// Les apports quotidiens sautent trop d'un jour à l'autre — un repas de
    /// famille, un jour de jeûne — pour qu'on lise quoi que ce soit sur la
    /// courbe brute. Aplatir chaque semaine donne un escalier où la tendance
    /// saute aux yeux.
    ///
    /// La moyenne ne porte que sur les jours réellement enregistrés du bloc :
    /// une semaine où seuls deux jours ont été saisis n'est pas tirée vers le
    /// bas par cinq zéros fictifs.
    private func smoothed(_ points: [ChartPoint]) -> [ChartPoint] {
        guard let first = points.first?.date else { return points }
        let cal = Calendar.current

        var out: [ChartPoint] = []
        var bucket: [ChartPoint] = []
        var bucketStart = first

        func flush() {
            guard !bucket.isEmpty else { return }
            let avg = bucket.reduce(0) { $0 + $1.value } / Double(bucket.count)
            out.append(contentsOf: bucket.map { ChartPoint(date: $0.date, value: avg) })
            bucket = []
        }

        for p in points {
            let elapsed = cal.dateComponents([.day], from: bucketStart, to: p.date).day ?? 0
            if elapsed >= smoothingWindow {
                flush()
                // On recale sur un multiple entier de la fenêtre : les blocs
                // restent alignés même après plusieurs jours sans saisie.
                let jumps = elapsed / smoothingWindow
                bucketStart = cal.date(byAdding: .day,
                                       value: jumps * smoothingWindow,
                                       to: bucketStart) ?? p.date
            }
            bucket.append(p)
        }
        flush()
        return out
    }

    /// Projection linéaire — 1 point par jour à venir (mode poids uniquement).
    private var projPoints: [ChartPoint] {
        guard mode == 0, projDays > 0, sortedEntries.count >= 3,
              let firstStr = sortedEntries.first?.date,
              let last = sortedEntries.last,
              let lastDate = DateHelper.date(from: last.date)
        else { return [] }

        let xs = sortedEntries.map { Double(DateHelper.days(from: firstStr, to: $0.date)) }
        let ys = sortedEntries.map { $0.w }
        guard let reg = Calc.linReg(xs: xs, ys: ys) else { return [] }

        let lastX = xs.last ?? 0
        // Premier point = dernière pesée réelle (raccord visuel)
        var pts: [ChartPoint] = [ChartPoint(date: lastDate, value: last.w)]
        for p in 1...projDays {
            guard let d = Calendar.current.date(byAdding: .day, value: p, to: lastDate)
            else { continue }
            pts.append(ChartPoint(date: d,
                                  value: reg.slope * (lastX + Double(p)) + reg.intercept))
        }
        return pts
    }
}
