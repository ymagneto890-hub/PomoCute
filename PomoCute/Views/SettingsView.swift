import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vm: TimerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Tiempos Pomodoro")) {
                    Stepper(value: $vm.focusMinutes, in: 1...90) {
                        HStack {
                            Text("🍅 Enfoque")
                                .fontWeight(.semibold)
                            Spacer()
                            Text("\(vm.focusMinutes) min")
                                .foregroundColor(.gray)
                        }
                    }

                    Stepper(value: $vm.shortBreakMinutes, in: 1...30) {
                        HStack {
                            Text("🍵 Descanso Corto")
                                .fontWeight(.semibold)
                            Spacer()
                            Text("\(vm.shortBreakMinutes) min")
                                .foregroundColor(.gray)
                        }
                    }

                    Stepper(value: $vm.longBreakMinutes, in: 1...60) {
                        HStack {
                            Text("🌙 Descanso Largo")
                                .fontWeight(.semibold)
                            Spacer()
                            Text("\(vm.longBreakMinutes) min")
                                .foregroundColor(.gray)
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
            .navigationTitle("⚙️ Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(red: 1.0, green: 0.40, blue: 0.52))
                }
            }
        }
    }
}
