import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: TimerViewModel

    @State private var showBasket = false
    @State private var showSettings = false

    var progress: Double {
        guard vm.totalSeconds > 0 else { return 0 }
        return Double(vm.remainingSeconds) / Double(vm.totalSeconds)
    }

    var body: some View {
        ZStack {
            // Fondo dinámico pastel según el modo
            vm.mode.bgColor
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.3), value: vm.mode)

            VStack(spacing: 16) {
                // MARK: - Barra Superior Compacta (iPhone SE)
                HStack {
                    HStack(spacing: 6) {
                        Text("🌸")
                            .font(.system(size: 20))
                        Text("PomoCute")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(Color(red: 0.25, green: 0.18, blue: 0.22))
                    }

                    Spacer()

                    // Chip Rápido de Cesta
                    Button(action: {
                        vm.playPop()
                        showBasket = true
                    }) {
                        HStack(spacing: 5) {
                            Text("🧺")
                                .font(.system(size: 14))
                            Text(vm.formatMinutesHours(vm.todayMinutes))
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .foregroundColor(Color(red: 0.35, green: 0.25, blue: 0.30))
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }

                    // Botón Ajustes
                    Button(action: {
                        vm.playPop()
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 0.45, green: 0.35, blue: 0.40))
                            .padding(8)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)

                // MARK: - Selector de Modos Píldora Kawaii
                HStack(spacing: 4) {
                    ForEach(PomodoroMode.allCases) { m in
                        Button(action: {
                            vm.setMode(m)
                        }) {
                            HStack(spacing: 5) {
                                Text(m.emoji)
                                    .font(.system(size: 14))
                                Text(m.rawValue)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(vm.mode == m ? Color.white : Color.clear)
                            .foregroundColor(vm.mode == m ? m.accentColor : Color.gray)
                            .cornerRadius(16)
                            .shadow(color: vm.mode == m ? Color.black.opacity(0.06) : Color.clear, radius: 4, x: 0, y: 2)
                        }
                    }
                }
                .padding(4)
                .background(Color(red: 0.93, green: 0.88, blue: 0.90).opacity(0.6))
                .cornerRadius(20)
                .padding(.horizontal, 20)

                Spacer(minLength: 4)

                // MARK: - Círculo Principal con Tomatito y Reloj
                ZStack {
                    // Pista de fondo
                    Circle()
                        .stroke(Color.white.opacity(0.85), lineWidth: 10)
                        .frame(width: 230, height: 230)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)

                    // Progreso Circular Suave
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(
                            vm.mode.accentColor,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 230, height: 230)
                        .animation(.linear(duration: 0.25), value: progress)

                    // Contenido Central
                    VStack(spacing: 6) {
                        TomatoMascotView()

                        Text(vm.formattedTime())
                            .font(.system(size: 44, weight: .black, design: .monospaced))
                            .foregroundColor(Color(red: 0.22, green: 0.15, blue: 0.18))

                        // Ajustador Rápido (- / +)
                        HStack(spacing: 12) {
                            Button(action: { vm.adjustCurrentModeMinutes(delta: -1) }) {
                                Text("−")
                                    .font(.system(size: 16, weight: .bold))
                                    .frame(width: 26, height: 26)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)
                            }

                            Text("\(vm.totalSeconds / 60) min")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.40, green: 0.30, blue: 0.35))

                            Button(action: { vm.adjustCurrentModeMinutes(delta: 1) }) {
                                Text("+")
                                    .font(.system(size: 16, weight: .bold))
                                    .frame(width: 26, height: 26)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)
                            }
                        }
                        .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.25))
                    }
                }

                // Indicador de 4 ciclos (tomatitos)
                HStack(spacing: 8) {
                    ForEach(0..<vm.cycleTarget, id: \.self) { index in
                        if index < (vm.completedCycles % vm.cycleTarget) {
                            Text("🍅")
                                .font(.system(size: 16))
                        } else if index == (vm.completedCycles % vm.cycleTarget) && vm.mode == .focus {
                            Text("🍅")
                                .font(.system(size: 16))
                                .scaleEffect(1.2)
                        } else {
                            Circle()
                                .fill(Color.white.opacity(0.9))
                                .frame(width: 12, height: 12)
                        }
                    }
                }
                .padding(.top, 4)

                Spacer(minLength: 4)

                // MARK: - Botones Principales de Control
                HStack(spacing: 24) {
                    // Reiniciar
                    Button(action: vm.reset) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(red: 0.45, green: 0.35, blue: 0.40))
                            .frame(width: 48, height: 48)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                    }

                    // Botón Principal Play / Pause
                    Button(action: vm.toggle) {
                        Image(systemName: vm.isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 72, height: 72)
                            .background(vm.mode.accentColor)
                            .clipShape(Circle())
                            .shadow(color: vm.mode.accentColor.opacity(0.4), radius: 10, x: 0, y: 5)
                    }

                    // Saltar ciclo
                    Button(action: vm.skip) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(red: 0.45, green: 0.35, blue: 0.40))
                            .frame(width: 48, height: 48)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                    }
                }

                // MARK: - Resumen Inferior Cesta
                Button(action: {
                    vm.playPop()
                    showBasket = true
                }) {
                    HStack(spacing: 6) {
                        Text("🧺 Cosecha de hoy:")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.gray)
                        Text("\(vm.todayTomatoes) tomatitos")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 1.0, green: 0.40, blue: 0.52))
                        Text("(\(vm.todayMinutes) min)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.gray)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.75))
                    .cornerRadius(16)
                }
                .padding(.bottom, 12)
            }
        }
        .sheet(isPresented: $showBasket) {
            BasketView()
                .environmentObject(vm)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(vm)
        }
    }
}
