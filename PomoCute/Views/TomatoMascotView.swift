import SwiftUI

struct TomatoMascotView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var isBouncing = false
    @State private var isBlinking = false

    var body: some View {
        ZStack {
            // Hojitas verdes superiores
            VStack(spacing: -8) {
                HStack(spacing: 3) {
                    Capsule()
                        .fill(Color(red: 0.35, green: 0.78, blue: 0.45))
                        .frame(width: 11, height: 20)
                        .rotationEffect(.degrees(-32))
                    Capsule()
                        .fill(Color(red: 0.35, green: 0.78, blue: 0.45))
                        .frame(width: 13, height: 24)
                    Capsule()
                        .fill(Color(red: 0.35, green: 0.78, blue: 0.45))
                        .frame(width: 11, height: 20)
                        .rotationEffect(.degrees(32))
                }
                .offset(y: -3)

                // Cuerpo del Tomate Kawaii
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.48, blue: 0.58), Color(red: 0.98, green: 0.35, blue: 0.48)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 68, height: 68)
                        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)

                    // Brillo en la cabeza
                    Circle()
                        .fill(Color.white.opacity(0.35))
                        .frame(width: 13, height: 13)
                        .offset(x: -16, y: -16)

                    // Carita Kawaii (Calcada fielmente del icono de la app)
                    VStack(spacing: 4) {
                        // Ojos Kawaii
                        HStack(spacing: 16) {
                            // Ojo Izquierdo
                            if isBlinking {
                                Capsule()
                                    .fill(Color(red: 0.25, green: 0.18, blue: 0.22))
                                    .frame(width: 6, height: 2)
                            } else {
                                Capsule()
                                    .fill(Color(red: 0.25, green: 0.18, blue: 0.22))
                                    .frame(width: 5.5, height: 7.5)
                            }

                            // Ojo Derecho
                            if isBlinking {
                                Capsule()
                                    .fill(Color(red: 0.25, green: 0.18, blue: 0.22))
                                    .frame(width: 6, height: 2)
                            } else {
                                Capsule()
                                    .fill(Color(red: 0.25, green: 0.18, blue: 0.22))
                                    .frame(width: 5.5, height: 7.5)
                            }
                        }

                        // Boca sonriente (U feliz centrada debajo de los ojos)
                        Circle()
                            .trim(from: 0.05, to: 0.45)
                            .stroke(Color(red: 0.25, green: 0.18, blue: 0.22), style: StrokeStyle(lineWidth: 2.0, lineCap: .round))
                            .frame(width: 11, height: 11)
                            .offset(y: -1)
                    }
                    .offset(y: 3)

                    // Mejillas sonrosadas (Blush)
                    HStack(spacing: 28) {
                        Circle()
                            .fill(Color(red: 1.0, green: 0.70, blue: 0.76).opacity(0.85))
                            .frame(width: 8, height: 6)
                        Circle()
                            .fill(Color(red: 1.0, green: 0.70, blue: 0.76).opacity(0.85))
                            .frame(width: 8, height: 6)
                    }
                    .offset(y: 7)
                }
            }
        }
        .scaleEffect(isBouncing ? 1.15 : 1.0)
        .rotationEffect(.degrees(isBouncing ? 5 : 0))
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.45)) {
                isBouncing = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.2)) {
                    isBouncing = false
                }
            }
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else {
                isBlinking = false
                return
            }
            do {
                while !Task.isCancelled {
                    try await Task.sleep(nanoseconds: 6_000_000_000)
                    try Task.checkCancellation()
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isBlinking = true
                    }
                    try await Task.sleep(nanoseconds: 180_000_000)
                    try Task.checkCancellation()
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isBlinking = false
                    }
                }
            } catch {
                // Task is cancelled when the view disappears or the app leaves the foreground.
            }
        }
    }
}
