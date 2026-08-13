//
//  DateHelper.swift
//  Dates au format "YYYY-MM-DD" en HEURE LOCALE (pas d'UTC).
//

import Foundation

enum DateHelper {
    private static let iso: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    /// Date du jour "YYYY-MM-DD" (heure locale)
    static var today: String { iso.string(from: Date()) }

    /// "YYYY-MM-DD" -> Date locale (minuit)
    static func date(from s: String) -> Date? { iso.date(from: s) }

    /// Date -> "YYYY-MM-DD" (heure locale)
    static func dateString(_ d: Date) -> String { iso.string(from: d) }

    /// "YYYY-MM-DD" -> "DD/MM/YYYY"
    static func display(_ s: String) -> String {
        let p = s.split(separator: "-")
        guard p.count == 3 else { return s }
        return "\(p[2])/\(p[1])/\(p[0])"
    }

    /// Jour précédent au format "YYYY-MM-DD"
    static func previous(_ s: String) -> String {
        guard let d = date(from: s),
              let prev = Calendar.current.date(byAdding: .day, value: -1, to: d)
        else { return s }
        return iso.string(from: prev)
    }

    /// Jour suivant au format "YYYY-MM-DD"
    static func next(_ s: String) -> String {
        guard let d = date(from: s),
              let nxt = Calendar.current.date(byAdding: .day, value: 1, to: d)
        else { return s }
        return iso.string(from: nxt)
    }

    /// Nombre de jours entre deux dates "YYYY-MM-DD"
    static func days(from a: String, to b: String) -> Int {
        guard let da = date(from: a), let db = date(from: b) else { return 0 }
        return Calendar.current.dateComponents([.day], from: da, to: db).day ?? 0
    }

    /// Prochaine occurrence d'un mois/jour (année suivante si déjà passé)
    static func nextOccurrence(month: Int, day: Int) -> Date {
        let cal = Calendar.current
        let now = Date()
        var comps = cal.dateComponents([.year], from: now)
        comps.month = month
        comps.day = day
        var d = cal.date(from: comps) ?? now
        if d <= now {
            comps.year = (comps.year ?? cal.component(.year, from: now)) + 1
            d = cal.date(from: comps) ?? now
        }
        return d
    }

    /// Nombre de jours entre aujourd'hui et une date
    static func daysUntil(_ date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
    }
}
