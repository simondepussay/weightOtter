//
//  SplashView.swift
//  Écran d'accueil animé : défilement d'étoiles façon hyperespace,
//  affiché ~2,6 s au lancement avant l'app.
//

import SwiftUI
import Combine

/// Une étoile en coordonnées 3D simplifiées (x,y dans [-1,1], z = profondeur).
struct WStar {
    var x: Double
    var y: Double
    var z: Double
    var pz: Double   // z précédent → pour la traînée

    static func random(far: Bool = false) -> WStar {
        let x = Double.random(in: -1...1)
        let y = Double.random(in: -1...1)
        let z = far ? 1.0 : Double.random(in: 0.1...1.0)
        return WStar(x: x, y: y, z: z, pz: z)
    }
}

struct SplashView: View {
    var onFinish: () -> Void

    @State private var stars: [WStar] = (0..<200).map { _ in WStar.random() }
    @State private var logoOpacity = 0.0
    @State private var finished = false
    @State private var start = Date()

    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.woBg.ignoresSafeArea()

            // Champ d'étoiles en mouvement
            Canvas { ctx, size in
                let cx = size.width / 2
                let cy = size.height / 2
                for s in stars {
                    guard s.z > 0.02, s.pz > 0.02 else { continue }
                    let sx = cx + (s.x / s.z) * cx
                    let sy = cy + (s.y / s.z) * cy
                    let px = cx + (s.x / s.pz) * cx
                    let py = cy + (s.y / s.pz) * cy
                    let depth   = 1 - s.z                       // 0 loin → 1 proche
                    let width   = max(0.4, depth * 2.6)
                    let opacity = min(1.0, depth * 1.6 + 0.15)

                    var path = Path()
                    path.move(to: CGPoint(x: px, y: py))
                    path.addLine(to: CGPoint(x: sx, y: sy))
                    ctx.stroke(path,
                               with: .color(.white.opacity(opacity)),
                               lineWidth: width)
                }
            }
            .ignoresSafeArea()

            // Logo + mascotte
            VStack(spacing: 14) {
                Image("spaceotter")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 110, height: 110)
                    .shadow(color: .woBlue.opacity(0.6), radius: 16)
                Text("⚖ WEIGHTOTTER")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.woBlue)
                    .shadow(color: .woBlue.opacity(0.7), radius: 10)
            }
            .opacity(logoOpacity)
        }
        .onReceive(timer) { _ in advance() }
        .onAppear {
            withAnimation(.easeIn(duration: 0.8)) { logoOpacity = 1 }
        }
    }

    private func advance() {
        for i in stars.indices {
            stars[i].pz = stars[i].z
            stars[i].z -= 0.011
            if stars[i].z <= 0.05 {
                stars[i] = WStar.random(far: true)
            }
        }
        if !finished, Date().timeIntervalSince(start) > 2.6 {
            finished = true
            onFinish()
        }
    }
}
