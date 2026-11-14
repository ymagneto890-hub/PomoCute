import SwiftUI
import UIKit

struct BasketView: View {
    @EnvironmentObject var vm: TimerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var resetConfirmation: ResetConfirmation?

    var body: some View {
        let weekDays = vm.currentWeekDays()
        let maxAxisHours = vm.chartMaxAxisHours(for: weekDays)

        VStack(spacing: 0) {
            // MARK: - Barra Superior Personalizada
            HStack {
                Text("🧺 Tu Cesta de Enfoque")
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .foregroundColor(Color(red: 0.25, green: 0.18, blue: 0.22))

                Spacer()

                Button(action: {
                    vm.playPop()
                    dismiss()
                }) {
                    Text("Cerrar")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color(red: 1.0, green: 0.40, blue: 0.52))
                        .clipShape(Capsule())
                        .shadow(color: Color(red: 1.0, green: 0.40, blue: 0.52).opacity(0.35), radius: 4, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 12)
            .background(Color(red: 0.99, green: 0.96, blue: 0.97))

            ScrollView {
                VStack(spacing: 18) {
                    // MARK: - Tarjeta Protagonista: Cabecera Dual + Gráfico de Barras Semanal
                    VStack(spacing: 0) {
                        // Cabecera Dual (Esta semana + Total histórico en Malva Suave)
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("🗓️ Esta semana")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 0.62, green: 0.54, blue: 0.58))

                                Text(vm.formatMinutesHours(vm.weekMinutes))
                                    .font(.system(size: 26, weight: .black, design: .rounded))
                                    .foregroundColor(Color(red: 1.0, green: 0.30, blue: 0.45))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Total histórico")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color(red: 0.69, green: 0.58, blue: 0.63))

                                HStack(spacing: 4) {
                                    Text("⭐")
                                        .font(.system(size: 12))
                                    Text(vm.formatMinutesHours(vm.totalMinutes))
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(red: 0.61, green: 0.49, blue: 0.54)) // Malva Suave (#9C7E8A)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color(red: 0.976, green: 0.949, blue: 0.957)) // Fondo Malva Pastel (#F9F2F4)
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.bottom, 14)

                        Rectangle()
                            .fill(Color(red: 0.97, green: 0.91, blue: 0.93))
                            .frame(height: 1)
                            .padding(.bottom, 12)

                        // Gráfico de Barras Clásico y Cute (Lunes a Domingo)
                        WeeklyBarChartView(
                            days: weekDays,
                            maxAxisHours: maxAxisHours,
                            valueFormatter: vm.formatShortBarValue
                        )
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(red: 1.0, green: 0.82, blue: 0.87), lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)

                    Spacer(minLength: 12)

                    // MARK: - Barra de Acciones para Limpiar
                    VStack(spacing: 12) {
                        Divider()

                        HStack {
                            Button("Vaciar cesta de hoy") {
                                resetConfirmation = .today
                            }
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 0.65, green: 0.45, blue: 0.55))

                            Spacer()

                            Button("Limpiar histórico total") {
                                resetConfirmation = .total
                            }
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.90, green: 0.25, blue: 0.30))
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                    }
                }
                .padding(18)
            }
        }
        .background(Color(red: 0.99, green: 0.96, blue: 0.97).ignoresSafeArea())
        .preferredColorScheme(.light)
        .alert(item: $resetConfirmation) { confirmation in
            switch confirmation {
            case .today:
                return Alert(
                    title: Text("¿Vaciar cesta de hoy?"),
                    message: Text("Se pondrán a 0m las horas trabajadas hoy. Los demás días y el total histórico se mantendrán."),
                    primaryButton: .destructive(Text("Vaciar"), action: vm.clearTodayStats),
                    secondaryButton: .cancel(Text("Cancelar"))
                )
            case .total:
                return Alert(
                    title: Text("¿Limpiar todo el histórico?"),
                    message: Text("Se pondrán a 0m tanto la gráfica semanal como todo el acumulado histórico."),
                    primaryButton: .destructive(Text("Borrar todo"), action: vm.clearAllStats),
                    secondaryButton: .cancel(Text("Cancelar"))
                )
            }
        }
    }
}

private enum ResetConfirmation: String, Identifiable {
    case today
    case total

    var id: String { rawValue }
}

// MARK: - Gráfico de Barras Semanal (Lun - Dom)
struct WeeklyBarChartView: View {
    let days: [DayBarData]
    let maxAxisHours: Int
    let valueFormatter: (Int) -> String

    private let topHeadroom: CGFloat = 18
    private let plotHeight: CGFloat = 148
    private let bottomLabelsHeight: CGFloat = 24

    private var axisTicks: [Int] {
        let step = max(1, maxAxisHours / 4)
        return [step * 4, step * 3, step * 2, step, 0]
    }

    private var maxAxisMinutes: CGFloat {
        CGFloat(max(1, maxAxisHours * 60))
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Eje Y (Horas: 4h, 3h, 2h, 1h, 0h)
            VStack(alignment: .trailing, spacing: 0) {
                ForEach(Array(axisTicks.enumerated()), id: \.offset) { idx, hour in
                    Text("\(hour)h")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.69, green: 0.58, blue: 0.63))
                        .frame(height: 12)
                    if idx < axisTicks.count - 1 {
                        Spacer(minLength: 0)
                    }
                }
            }
            .frame(width: 26, height: plotHeight + 12)
            .padding(.top, topHeadroom - 6)

            // Área de trazado (Cuadrícula + Barras + Eje X)
            ZStack(alignment: .top) {
                // 1. Líneas de cuadrícula horizontales y línea base 0h
                VStack(spacing: 0) {
                    ForEach(0..<4, id: \.self) { _ in
                        HorizontalDashedLine()
                            .stroke(
                                Color(red: 0.96, green: 0.88, blue: 0.91),
                                style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                            )
                            .frame(height: 1)
                        Spacer(minLength: 0)
                    }
                    // Línea base sólida del Eje X (0h)
                    Rectangle()
                        .fill(Color(red: 0.91, green: 0.77, blue: 0.82))
                        .frame(height: 1.5)
                }
                .frame(height: plotHeight)
                .padding(.top, topHeadroom)

                // 2. Columnas de barras naciendo desde la línea base 0h
                VStack(spacing: 0) {
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(days) { day in
                            VStack(spacing: 3) {
                                Spacer(minLength: 0)

                                if day.minutes > 0 {
                                    Text(valueFormatter(day.minutes))
                                        .font(.system(size: 11, weight: day.isToday ? .heavy : .bold, design: .rounded))
                                        .foregroundColor(
                                            day.isToday
                                                ? Color(red: 1.0, green: 0.30, blue: 0.45)
                                                : Color(red: 0.55, green: 0.42, blue: 0.47)
                                        )
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)

                                    let clampedMins = min(CGFloat(day.minutes), maxAxisMinutes)
                                    let barHeight = max(6, plotHeight * (clampedMins / maxAxisMinutes))

                                    TopRoundedBarShape(radius: 6)
                                        .fill(
                                            day.isToday
                                                ? Color(red: 1.0, green: 0.40, blue: 0.52) // #FF6685
                                                : Color(red: 1.0, green: 0.64, blue: 0.72) // #FFA3B8
                                        )
                                        .frame(maxWidth: 26)
                                        .frame(height: barHeight)
                                } else {
                                    TopRoundedBarShape(radius: 1)
                                        .fill(Color(red: 0.91, green: 0.77, blue: 0.82))
                                        .frame(maxWidth: 26)
                                        .frame(height: 2)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        }
                    }
                    .frame(height: topHeadroom + plotHeight)
                    .padding(.horizontal, 2)

                    // 3. Etiquetas del Eje X (L, M, X, J, V, S, D)
                    HStack(spacing: 8) {
                        ForEach(days) { day in
                            Text(day.shortLabel)
                                .font(.system(size: 12, weight: day.isToday ? .heavy : .bold, design: .rounded))
                                .foregroundColor(
                                    day.isToday
                                        ? Color(red: 1.0, green: 0.30, blue: 0.45)
                                        : (day.minutes > 0
                                            ? Color(red: 0.48, green: 0.36, blue: 0.41)
                                            : Color(red: 0.69, green: 0.58, blue: 0.63))
                                )
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: bottomLabelsHeight)
                    .padding(.horizontal, 2)
                }
            }
            .frame(height: topHeadroom + plotHeight + bottomLabelsHeight)
        }
    }
}

private struct HorizontalDashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

private struct TopRoundedBarShape: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let bezier = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(bezier.cgPath)
    }
}
