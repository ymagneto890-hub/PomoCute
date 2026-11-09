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
    // MARK: - Estado de Temporizador Reactivo
    @Published var mode: PomodoroMode = .focus
    @Published var isRunning: Bool = false
    @Published var remainingSeconds: Int = 25 * 60
    @Published var totalSeconds: Int = 25 * 60
    @Published var completedCycles: Int = 0

    // MARK: - Ajustes de Tiempo (Reactivos y persistidos en UserDefaults)
    @Published var focusMinutes: Int {
        didSet {
            UserDefaults.standard.set(focusMinutes, forKey: "focusMinutes")
            if !isRunning && mode == .focus {
                applyModeDuration(for: .focus)
            }
        }
    }

    @Published var shortBreakMinutes: Int {
        didSet {
            UserDefaults.standard.set(shortBreakMinutes, forKey: "shortBreakMinutes")
            if !isRunning && mode == .shortBreak {
                applyModeDuration(for: .shortBreak)
            }
        }
    }

    @Published var longBreakMinutes: Int {
        didSet {
            UserDefaults.standard.set(longBreakMinutes, forKey: "longBreakMinutes")
            if !isRunning && mode == .longBreak {
                applyModeDuration(for: .longBreak)
            }
        }
    }

    @Published var cycleTarget: Int {
        didSet { UserDefaults.standard.set(cycleTarget, forKey: "cycleTarget") }
    }

    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled") }
    }

    @Published var hapticEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticEnabled, forKey: "hapticEnabled") }
    }

    // MARK: - Estadísticas y Cesta (Reactivos y persistidos en UserDefaults)
    @Published var todayMinutes: Int {
        didSet { UserDefaults.standard.set(todayMinutes, forKey: "todayMinutes") }
    }

    @Published var todayTomatoes: Int {
        didSet { UserDefaults.standard.set(todayTomatoes, forKey: "todayTomatoes") }
    }

    @Published var totalMinutes: Int {
        didSet { UserDefaults.standard.set(totalMinutes, forKey: "totalMinutes") }
    }

    @Published var totalTomatoes: Int {
        didSet { UserDefaults.standard.set(totalTomatoes, forKey: "totalTomatoes") }
    }

    private var targetEndTime: Date?
    private var timerSubscription: Timer?
    private let notificationId = "pomocute_timer_notification"

    init() {
        let defaults = UserDefaults.standard
        let fM = defaults.integer(forKey: "focusMinutes")
        self.focusMinutes = fM > 0 ? fM : 25

        let sM = defaults.integer(forKey: "shortBreakMinutes")
        self.shortBreakMinutes = sM > 0 ? sM : 5

        let lM = defaults.integer(forKey: "longBreakMinutes")
        self.longBreakMinutes = lM > 0 ? lM : 15

        let cT = defaults.integer(forKey: "cycleTarget")
        self.cycleTarget = cT > 0 ? cT : 4

        self.soundEnabled = defaults.object(forKey: "soundEnabled") == nil ? true : defaults.bool(forKey: "soundEnabled")
        self.hapticEnabled = defaults.object(forKey: "hapticEnabled") == nil ? true : defaults.bool(forKey: "hapticEnabled")

        self.todayMinutes = defaults.integer(forKey: "todayMinutes")
        self.todayTomatoes = defaults.integer(forKey: "todayTomatoes")
        self.totalMinutes = defaults.integer(forKey: "totalMinutes")
        self.totalTomatoes = defaults.integer(forKey: "totalTomatoes")

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
        let lastDate = UserDefaults.standard.string(forKey: "lastDateString") ?? ""
        if lastDate != todayStr {
            todayMinutes = 0
            todayTomatoes = 0
            UserDefaults.standard.set(todayStr, forKey: "lastDateString")
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
