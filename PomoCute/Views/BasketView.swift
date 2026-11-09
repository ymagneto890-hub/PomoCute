import SwiftUI

struct BasketView: View {
    @EnvironmentObject var vm: TimerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showConfirmResetToday = false
    @State private var showConfirmResetTotal = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Tarjetas de Estadísticas
                    HStack(spacing: 12) {
                        StatCard(
                            icon: "📅",
                            value: vm.formatMinutesHours(vm.todayMinutes),
                            label: "Trabajado Hoy"
                        )
                        StatCard(
                            icon: "🍅",
                            value: "\(vm.todayTomatoes)",
                            label: "Tomates Hoy"
                        )
                    }

                    // Total acumulado histórico
                    HStack(spacing: 16) {
                        Text("⭐")
                            .font(.system(size: 28))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(vm.formatMinutesHours(vm.totalMinutes))
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.25, green: 0.18, blue: 0.22))
                            Text("Total Acumulado Histórico")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.gray)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(18)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)

                    // Cesta Gráfica de Tomatitos
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tomatitos cosechados hoy:")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.35, green: 0.25, blue: 0.30))

                        ZStack {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color(red: 0.99, green: 0.96, blue: 0.97))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color(red: 1.0, green: 0.85, blue: 0.89), lineWidth: 1.5)
                                )

                            if vm.todayTomatoes == 0 {
                                Text("¡Empieza una sesión de enfoque para cosechar tu primer tomatito! 🍅🌱")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(24)
                            } else {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 36))], spacing: 10) {
                                    ForEach(0..<min(vm.todayTomatoes, 40), id: \.self) { _ in
                                        Text("🍅")
                                            .font(.system(size: 24))
                                    }
                                    if vm.todayTomatoes > 40 {
                                        Text("+\(vm.todayTomatoes - 40) más")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(16)
                            }
                        }
                        .frame(minHeight: 120)
                    }

                    Spacer(minLength: 16)

                    // Barra de Acciones para Limpiar
                    VStack(spacing: 12) {
                        Divider()

                        HStack {
                            Button("Vaciar cesta de hoy") {
                                showConfirmResetToday = true
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(red: 0.65, green: 0.45, blue: 0.55))

                            Spacer()

                            Button("Limpiar histórico total") {
                                showConfirmResetTotal = true
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(red: 0.90, green: 0.25, blue: 0.30))
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                    }
                }
                .padding(18)
            }
            .background(Color(red: 0.99, green: 0.97, blue: 0.98).ignoresSafeArea())
            .navigationTitle("🧺 Tu Cesta de Enfoque")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(red: 1.0, green: 0.40, blue: 0.52))
                }
            }
            .alert("¿Vaciar cesta de hoy?", isPresented: $showConfirmResetToday) {
                Button("Cancelar", role: .cancel) {}
                Button("Vaciar", role: .destructive) {
                    vm.clearTodayStats()
                }
            } message: {
                Text("Se pondrán a 0 los tomates y minutos cosechados hoy. El total histórico se mantendrá.")
            }
            .alert("¿Limpiar todo el histórico?", isPresented: $showConfirmResetTotal) {
                Button("Cancelar", role: .cancel) {}
                Button("Borrar todo", role: .destructive) {
                    vm.clearAllStats()
                }
            } message: {
                Text("Se pondrán a 0h 0m tanto las estadísticas de hoy como todo el acumulado histórico.")
            }
        }
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Text(icon)
                .font(.system(size: 26))
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.25, green: 0.18, blue: 0.22))
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}
