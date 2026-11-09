import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vm: TimerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Tiempos de Sesión")) {
                    Stepper(value: $vm.focusMinutes, in: 1...90) {
                        HStack {
                            Text("🍅 Enfoque")
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            Spacer()
                            Text("\(vm.focusMinutes) min")
                                .foregroundColor(.secondary)
                        }
                    }

                    Stepper(value: $vm.shortBreakMinutes, in: 1...30) {
                        HStack {
                            Text("🍵 Corto")
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            Spacer()
                            Text("\(vm.shortBreakMinutes) min")
                                .foregroundColor(.secondary)
                        }
                    }

                    Stepper(value: $vm.longBreakMinutes, in: 1...60) {
                        HStack {
                            Text("🌙 Largo")
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            Spacer()
                            Text("\(vm.longBreakMinutes) min")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section(header: Text("Sonido y Vibración")) {
                    Toggle("Efectos de sonido", isOn: $vm.soundEnabled)
                    Toggle("Vibración háptica", isOn: $vm.hapticEnabled)

                    Button(action: {
                        vm.playChime()
                        vm.triggerHaptic()
                    }) {
                        HStack {
                            Text("🔔 Probar campanita")
                                .foregroundColor(Color(red: 1.0, green: 0.40, blue: 0.52))
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }

                Section {
                    Button(role: .destructive, action: {
                        vm.playPop()
                        vm.focusMinutes = 25
                        vm.shortBreakMinutes = 5
                        vm.longBreakMinutes = 15
                    }) {
                        HStack {
                            Spacer()
                            Text("Restablecer a 25 / 5 / 15 min")
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                        }
                    }
                }
            }
            .preferredColorScheme(.light)
            .navigationTitle("⚙️ Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") {
                        vm.playPop()
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(red: 1.0, green: 0.40, blue: 0.52))
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}
