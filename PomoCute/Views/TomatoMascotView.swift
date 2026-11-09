import SwiftUI

struct TomatoMascotView: View {
    @State private var isBouncing = false
    @State private var isBlinking = false
    @State private var blinkTimer: Timer?

    var body: some View {
        ZStack {
            // Hojitas verdes superiores
            VStack(spacing: -10) {
                HStack(spacing: 4) {
                    Capsule()
                        .fill(Color(red: 0.35, green: 0.78, blue: 0.45))
                        .frame(width: 14, height: 26)
                        .rotationEffect(.degrees(-32))
                    Capsule()
                        .fill(Color(red: 0.35, green: 0.78, blue: 0.45))
                        .frame(width: 16, height: 30)
                    Capsule()
                        .fill(Color(red: 0.35, green: 0.78, blue: 0.45))
                        .frame(width: 14, height: 26)
                        .rotationEffect(.degrees(32))
                }
                .offset(y: -4)

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
                        .frame(width: 82, height: 82)
                        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)

                    // Brillo en la cabeza
                    Circle()
                        .fill(Color.white.opacity(0.35))
                        .frame(width: 16, height: 16)
                        .offset(x: -20, y: -20)

                    // Carita Kawaii
                    HStack(spacing: 14) {
                        // Ojo Izquierdo
                        VStack {
                            if isBlinking {
                                Capsule()
                                    .fill(Color(red: 0.25, green: 0.18, blue: 0.22))
                                    .frame(width: 7, height: 2)
                            } else {
                                Circle()
                                    .fill(Color(red: 0.25, green: 0.18, blue: 0.22))
                                    .frame(width: 7, height: 7)
                            }
                        }

                        // Boca sonriente
                        Circle()
                            .trim(from: 0.05, to: 0.45)
                            .stroke(Color(red: 0.3, green: 0.15, blue: 0.2), lineWidth: 2.2)
                            .frame(width: 12, height: 12)
                            .rotationEffect(.degrees(180))
                            .offset(y: 2)

                        // Ojo Derecho
                        VStack {
                            if isBlinking {
                                Capsule()
                                    .fill(Color(red: 0.25, green: 0.18, blue: 0.22))
                                    .frame(width: 7, height: 2)
                            } else {
                                Circle()
                                    .fill(Color(red: 0.25, green: 0.18, blue: 0.22))
                                    .frame(width: 7, height: 7)
                            }
                        }
                    }

                    // Mejillas sonrosadas (Blush)
                    HStack(spacing: 34) {
                        Circle()
                            .fill(Color(red: 1.0, green: 0.70, blue: 0.76).opacity(0.85))
                            .frame(width: 11, height: 8)
                        Circle()
                            .fill(Color(red: 1.0, green: 0.70, blue: 0.76).opacity(0.85))
                            .frame(width: 11, height: 8)
                    }
                    .offset(y: 5)
                }
            }
        }
        .scaleEffect(isBouncing ? 1.18 : 1.0)
        .rotationEffect(.degrees(isBouncing ? 6 : 0))
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
        .onAppear {
            blinkTimer?.invalidate()
            blinkTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.1)) { isBlinking = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    withAnimation(.easeInOut(duration: 0.1)) { isBlinking = false }
                }
            }
        }
        .onDisappear {
            blinkTimer?.invalidate()
            blinkTimer = nil
        }
    }
}
