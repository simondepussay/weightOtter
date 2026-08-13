//
//  CollapsibleList.swift
//  Au-delà de 15 éléments (weightlist), on regroupe par blocs de 5 dépliables.


import SwiftUI

struct CollapsibleList<Item: Identifiable, Row: View>: View {
    let items: [Item]                 // ordre récent → ancien
    let date: (Item) -> String        // "YYYY-MM-DD"
    var spacing: CGFloat = 8
    var tint: Color = .woBlue
    @ViewBuilder let row: (Item) -> Row

    @State private var expanded: Set<Int> = []

    var body: some View {
        VStack(spacing: spacing) {
            if items.count <= 15 {
                ForEach(items) { row($0) }
            } else {
                ForEach(blocks.indices, id: \.self) { bi in
                    blockView(bi)
                }
            }
        }
    }

    // Découpe en paquets de 5
    private var blocks: [[Item]] {
        stride(from: 0, to: items.count, by: 5).map {
            Array(items[$0 ..< min($0 + 5, items.count)])
        }
    }

    @ViewBuilder
    private func blockView(_ bi: Int) -> some View {
        let slice = blocks[bi]
        let open  = expanded.contains(bi)

        VStack(spacing: spacing) {
            // En-tête : toucher pour déplier / replier
            Button {
                withAnimation { toggle(bi) }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: open ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10))
                    Text(rangeLabel(slice))
                        .font(.system(size: 12, design: .monospaced))
                    Spacer()
                    Text("\(slice.count)")
                        .font(.system(size: 11, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(tint.opacity(0.16))
                        .cornerRadius(10)
                }
                .foregroundColor(open ? tint : .woText2)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(Color.woCard)
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(open ? tint : Color.woBorder))
                .cornerRadius(8)
            }

            if open {
                ForEach(slice) { row($0) }

                // Petit bouton flèche-haut pour replier le groupe
                Button {
                    withAnimation { _ = expanded.remove(bi) }
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 11))
                        .foregroundColor(.woText2)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 26)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.woBorder))
                }
            }
        }
    }

    private func toggle(_ bi: Int) {
        if expanded.contains(bi) { expanded.remove(bi) } else { expanded.insert(bi) }
    }

    private func rangeLabel(_ slice: [Item]) -> String {
        guard let newest = slice.first, let oldest = slice.last else { return "" }
        let a = DateHelper.display(date(newest))
        let b = DateHelper.display(date(oldest))
        return a == b ? a : "\(a) → \(b)"
    }
}
