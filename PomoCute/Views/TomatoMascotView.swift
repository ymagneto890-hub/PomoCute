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

                    // Carita Kawaii
                    HStack(spacing: 11) {
                        // Ojo Izquierdo
                        VStack {
                            if isBlinking {
                                Capsule()
                                    .fill(Color(red: 0.25, green: 0.18, blue: 0.22))
                                    .frame(width: 6, height: 2)
                            } else {
                                Circle()
                                    .fill(Color(red: 0.25, green: 0.18, blue: 0.22))
                                    .frame(width: 6, height: 6)
                            }
                        }

                        // Boca sonriente
                        Circle()
                            .trim(from: 0.05, to: 0.45)
                            .stroke(Color(red: 0.3, green: 0.15, blue: 0.2), lineWidth: 2.0)
                            .frame(width: 10, height: 10)
                            .rotationEffect(.degrees(180))
                            .offset(y: 2)

                        // Ojo Derecho
                        VStack {
                            if isBlinking {
                                Capsule()
                                    .fill(Color(red: 0.25, green: 0.18, blue: 0.22))
                                    .frame(width: 6, height: 2)
                            } else {
                                Circle()
                                    .fill(Color(red: 0.25, green: 0.18, blue: 0.22))
                                    .frame(width: 6, height: 6)
                            }
                        }
                    }

                    // Mejillas sonrosadas (Blush)
                    HStack(spacing: 28) {
                        Circle()
                            .fill(Color(red: 1.0, green: 0.70, blue: 0.76).opacity(0.85))
                            .frame(width: 9, height: 7)
                        Circle()
                            .fill(Color(red: 1.0, green: 0.70, blue: 0.76).opacity(0.85))
                            .frame(width: 9, height: 7)
                    }
                    .offset(y: 4)
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
