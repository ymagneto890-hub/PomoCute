import Foundation
import SwiftUI
import UserNotifications
import AudioToolbox
import UIKit

enum PomodoroMode: String, CaseIterable, Identifiable {
    case focus = "Enfoque"
    case shortBreak = "Corto"
    case longBreak = "Largo"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .focus: return "🍅"
        case .shortBreak: return "🍵"
        case .longBreak: return "🌙"
        }
    }

    var accentColor: Color {
        switch self {
        case .focus: return Color(red: 1.0, green: 0.40, blue: 0.52)      // #FF6584
        case .shortBreak: return Color(red: 0.28, green: 0.73, blue: 0.47) // #48BB78
        case .longBreak: return Color(red: 0.62, green: 0.48, blue: 0.92)  // #9F7AEA
        }
    }

    var bgColor: Color {
        switch self {
        case .focus: return Color(red: 1.0, green: 0.96, blue: 0.96)
        case .shortBreak: return Color(red: 0.94, green: 0.98, blue: 0.95)
        case .longBreak: return Color(red: 0.96, green: 0.95, blue: 0.99)
        }
    }
}

final class TimerViewModel: ObservableObject {
    // MARK: - Estado de Temporizador
    @Published var mode: PomodoroMode = .focus
    @Published var isRunning: Bool = false
    @Published var remainingSeconds: Int = 25 * 60
    @Published var totalSeconds: Int = 25 * 60
    @Published var completedCycles: Int = 0

    // MARK: - Ajustes de Tiempo (en minutos)
    @AppStorage("focusMinutes") var focusMinutes: Int = 25
    @AppStorage("shortBreakMinutes") var shortBreakMinutes: Int = 5
    @AppStorage("longBreakMinutes") var longBreakMinutes: Int = 15
    @AppStorage("cycleTarget") var cycleTarget: Int = 4
    @AppStorage("soundEnabled") var soundEnabled: Bool = true
    @AppStorage("hapticEnabled") var hapticEnabled: Bool = true

    // MARK: - Estadísticas y Cesta (UserDefaults)
    @AppStorage("todayMinutes") var todayMinutes: Int = 0
    @AppStorage("todayTomatoes") var todayTomatoes: Int = 0
    @AppStorage("totalMinutes") var totalMinutes: Int = 0
    @AppStorage("totalTomatoes") var totalTomatoes: Int = 0
    @AppStorage("lastDateString") private var lastDateString: String = ""

    private var targetEndTime: Date?
    private var timerSubscription: Timer?
    private let notificationId = "pomocute_timer_notification"

    init() {
        checkAndResetDailyStats()
        applyModeDuration(for: .focus)
    }

    // MARK: - Control de Temporizador
    func toggle() {
        playPop()
        if isRunning {
            pause()
        } else {
            start()
        }
    }

    func start() {
        isRunning = true
        targetEndTime = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        scheduleNativeAlarm(seconds: remainingSeconds)

        timerSubscription?.invalidate()
        timerSubscription = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func pause() {
        isRunning = false
        targetEndTime = nil
        timerSubscription?.invalidate()
        timerSubscription = nil
        cancelNativeAlarm()
    }

    func reset() {
        playPop()
        pause()
        remainingSeconds = totalSeconds
    }

    func skip() {
        playPop()
        pause()
        handleCycleComplete()
    }

    func setMode(_ newMode: PomodoroMode) {
        guard mode != newMode else { return }
        playPop()
        pause()
        mode = newMode
        applyModeDuration(for: newMode)
    }

    func adjustCurrentModeMinutes(delta: Int) {
        playPop()
        switch mode {
        case .focus:
            focusMinutes = max(1, min(90, focusMinutes + delta))
        case .shortBreak:
            shortBreakMinutes = max(1, min(30, shortBreakMinutes + delta))
        case .longBreak:
            longBreakMinutes = max(1, min(60, longBreakMinutes + delta))
        }

        if !isRunning {
            applyModeDuration(for: mode)
        }
    }

    private func applyModeDuration(for targetMode: PomodoroMode) {
        let mins: Int
        switch targetMode {
        case .focus: mins = focusMinutes
        case .shortBreak: mins = shortBreakMinutes
        case .longBreak: mins = longBreakMinutes
        }
        totalSeconds = mins * 60
        remainingSeconds = totalSeconds
    }

    private func tick() {
        guard isRunning, let target = targetEndTime else { return }
        let diff = Int(ceil(target.timeIntervalSinceNow))
        if diff <= 0 {
            remainingSeconds = 0
            pause()
            handleCycleComplete()
        } else {
            remainingSeconds = diff
        }
    }

    func appDidBecomeActive() {
        checkAndResetDailyStats()
        guard isRunning, let target = targetEndTime else { return }
        let diff = Int(ceil(target.timeIntervalSinceNow))
        if diff <= 0 {
            remainingSeconds = 0
            pause()
            handleCycleComplete()
        } else {
            remainingSeconds = diff
        }
    }

    private func handleCycleComplete() {
        playChime()
        triggerHaptic()

        if mode == .focus {
            todayMinutes += focusMinutes
            todayTomatoes += 1
            totalMinutes += focusMinutes
            totalTomatoes += 1
            completedCycles += 1

            if completedCycles % cycleTarget == 0 {
                setMode(.longBreak)
            } else {
                setMode(.shortBreak)
            }
        } else {
            setMode(.focus)
        }
    }

    // MARK: - Limpieza de Histórico
    func clearTodayStats() {
        playPop()
        todayMinutes = 0
        todayTomatoes = 0
    }

    func clearAllStats() {
        playPop()
        todayMinutes = 0
        todayTomatoes = 0
        totalMinutes = 0
        totalTomatoes = 0
    }

    private func checkAndResetDailyStats() {
        let todayStr = getTodayString()
        if lastDateString != todayStr {
            todayMinutes = 0
            todayTomatoes = 0
            lastDateString = todayStr
        }
    }

    private func getTodayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    // MARK: - Notificaciones Nativas del Sistema
    private func scheduleNativeAlarm(seconds: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationId])

        let content = UNMutableNotificationContent()
        switch mode {
        case .focus:
            content.title = "🍅 ¡Sesión de Enfoque completada!"
            content.body = "¡Cosechaste 1 tomatito! Toca descansar un ratito 🍵"
        case .shortBreak:
            content.title = "🍵 Descanso corto terminado"
            content.body = "¿Listo para otra ronda de concentración? 🌸"
        case .longBreak:
            content.title = "🌙 Descanso largo terminado"
            content.body = "¡Energía recargada! A por el siguiente ciclo 🍅"
        }
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(max(1, seconds)), repeats: false)
        let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
        center.add(request)
    }

    private func cancelNativeAlarm() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
    }

    // MARK: - Sonidos y Hápticos
    func playPop() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(1057) // Pop sutil del sistema
    }

    func playChime() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(1025) // Campanita dulce de alerta
    }

    func triggerHaptic() {
        guard hapticEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    func formattedTime() -> String {
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    func formatMinutesHours(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h == 0 { return "\(m)m" }
        return "\(h)h \(m)m"
    }
}
