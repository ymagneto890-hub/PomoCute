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
        VStack(spacing: 0) {
            // MARK: - Barra Superior (Debajo de la barra de estado de iOS)
            HStack {
                HStack(spacing: 6) {
                    Text("🌸")
                        .font(.system(size: 18))
                    Text("PomoCute")
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundColor(Color(red: 0.25, green: 0.18, blue: 0.22))
                }

                Spacer()

                // Botón Ajustes
                Button(action: {
                    vm.playPop()
                    showSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(red: 0.45, green: 0.35, blue: 0.40))
                        .frame(width: 36, height: 36)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                }
                .accessibilityLabel("Ajustes")
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .alert("Notificaciones desactivadas", isPresented: $vm.notificationsDenied) {
                Button("Abrir Ajustes") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                    vm.notificationsDenied = false
                }
                Button("Ahora no", role: .cancel) {
                    vm.notificationsDenied = false
                }
            } message: {
                Text("Sin notificaciones no sonará el aviso con la pantalla bloqueada.")
            }

            // MARK: - Selector de Modos Píldora Kawaii
            HStack(spacing: 4) {
                ForEach(PomodoroMode.allCases) { m in
                    Button(action: {
                        vm.setMode(m)
                    }) {
                        HStack(spacing: 4) {
                            Text(m.emoji)
                                .font(.system(size: 13))
                            Text(m.rawValue)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(vm.mode == m ? Color.white : Color.clear)
                        .foregroundColor(vm.mode == m ? m.accentColor : Color.gray)
                        .cornerRadius(14)
                        .shadow(color: vm.mode == m ? Color.black.opacity(0.06) : Color.clear, radius: 3, x: 0, y: 1)
                    }
                }
            }
            .padding(3)
            .background(Color(red: 0.93, green: 0.88, blue: 0.90).opacity(0.6))
            .cornerRadius(18)
            .padding(.horizontal, 20)

            Spacer()

            // MARK: - Círculo Principal con Tomatito y Reloj
            ZStack {
                // Pista de fondo
                Circle()
                    .stroke(Color.white.opacity(0.85), lineWidth: 9)
                    .frame(width: 195, height: 195)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)

                // Progreso Circular
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        vm.mode.accentColor,
                        style: StrokeStyle(lineWidth: 9, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 195, height: 195)

                // Contenido Central: Mascota + Reloj
                VStack(spacing: 6) {
                    TomatoMascotView()

                    Text(vm.formattedTime())
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundColor(Color(red: 0.22, green: 0.15, blue: 0.18))
                }
            }

            Spacer()

            // MARK: - Indicador Fijo de Ciclos (100% idéntico en todas las pestañas)
            HStack(spacing: 8) {
                let completedInRound = vm.completedCycles % vm.cycleTarget
                ForEach(0..<vm.cycleTarget, id: \.self) { index in
                    ZStack {
                        if index < completedInRound {
                            Text("🍅")
                                .font(.system(size: 15))
                        } else {
                            Circle()
                                .fill(Color.white.opacity(0.85))
                                .frame(width: 12, height: 12)
                                .overlay(
                                    Circle()
                                        .stroke(vm.mode.accentColor.opacity(0.35), lineWidth: 1.5)
                                )
                                .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                        }
                    }
                    .frame(width: 22, height: 22)
                }
            }
            .frame(height: 24)

            Spacer()

            // MARK: - Botones Principales de Control
            HStack(spacing: 22) {
                // Reiniciar
                Button(action: vm.reset) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0.45, green: 0.35, blue: 0.40))
                        .frame(width: 44, height: 44)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                }
                .accessibilityLabel("Reiniciar")

                // Botón Principal Play / Pause
                Button(action: vm.toggle) {
                    Image(systemName: vm.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 64, height: 64)
                        .background(vm.mode.accentColor)
                        .clipShape(Circle())
                        .shadow(color: vm.mode.accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .accessibilityLabel(vm.isRunning ? "Pausar" : "Iniciar")

                // Saltar ciclo
                Button(action: vm.skip) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0.45, green: 0.35, blue: 0.40))
                        .frame(width: 44, height: 44)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                }
                .accessibilityLabel("Saltar")
            }

            Spacer()

            // MARK: - Tarjeta Inferior de Cesta e Histórico
            Button(action: {
                vm.playPop()
                showBasket = true
            }) {
                HStack(spacing: 10) {
                    Text("🧺")
                        .font(.system(size: 20))
                        .frame(width: 36, height: 36)
                        .background(Color(red: 1.0, green: 0.92, blue: 0.95))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 5) {
                            Text("Semana: \(vm.formatMinutesHours(vm.weekMinutes))")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 1.0, green: 0.38, blue: 0.50))
                            Text("•")
                                .foregroundColor(Color.gray.opacity(0.4))
                            Text("Hoy: \(vm.formatMinutesHours(vm.todayMinutes))")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.35, green: 0.25, blue: 0.30))
                        }

                        Text("Total: \(vm.formatMinutesHours(vm.totalMinutes)) • Ver gráfica")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(Color(red: 0.61, green: 0.49, blue: 0.54))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.70, green: 0.60, blue: 0.65))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.92))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .background(
            vm.mode.bgColor
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.3), value: vm.mode)
        )
        .sheet(isPresented: $showBasket) {
            BasketView()
                .environmentObject(vm)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(vm)
        }
        .alert("PomoCute", isPresented: $vm.showingCompletionAlert) {
            Button("Aceptar", role: .cancel) {
                vm.showingCompletionAlert = false
            }
        } message: {
            Text(vm.completionAlertMessage)
        }
        .preferredColorScheme(.light)
    }
}
