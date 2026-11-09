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
    // MARK: - Claves Constantes de UserDefaults
    private enum Keys {
        static let focusMinutes = "focusMinutes"
        static let shortBreakMinutes = "shortBreakMinutes"
        static let longBreakMinutes = "longBreakMinutes"
        static let cycleTarget = "cycleTarget"
        static let soundEnabled = "soundEnabled"
        static let hapticEnabled = "hapticEnabled"
        static let todayMinutes = "todayMinutes"
        static let todayTomatoes = "todayTomatoes"
        static let totalMinutes = "totalMinutes"
        static let totalTomatoes = "totalTomatoes"
        static let lastDateString = "lastDateString"
    }

    // MARK: - Estado de Temporizador Reactivo
    @Published var mode: PomodoroMode = .focus
    @Published var isRunning: Bool = false
    @Published var remainingSeconds: Int = 25 * 60
    @Published var totalSeconds: Int = 25 * 60
    @Published var completedCycles: Int = 0

    // MARK: - Ajustes de Tiempo (Reactivos y persistidos en UserDefaults)
    @Published var focusMinutes: Int {
        didSet {
            UserDefaults.standard.set(focusMinutes, forKey: Keys.focusMinutes)
            if !isRunning && mode == .focus {
                applyModeDuration(for: .focus)
            }
        }
    }

    @Published var shortBreakMinutes: Int {
        didSet {
            UserDefaults.standard.set(shortBreakMinutes, forKey: Keys.shortBreakMinutes)
            if !isRunning && mode == .shortBreak {
                applyModeDuration(for: .shortBreak)
            }
        }
    }

    @Published var longBreakMinutes: Int {
        didSet {
            UserDefaults.standard.set(longBreakMinutes, forKey: Keys.longBreakMinutes)
            if !isRunning && mode == .longBreak {
                applyModeDuration(for: .longBreak)
            }
        }
    }

    @Published var cycleTarget: Int {
        didSet { UserDefaults.standard.set(cycleTarget, forKey: Keys.cycleTarget) }
    }

    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: Keys.soundEnabled) }
    }

    @Published var hapticEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticEnabled, forKey: Keys.hapticEnabled) }
    }

    // MARK: - Estadísticas y Cesta (Reactivos y persistidos en UserDefaults)
    @Published var todayMinutes: Int {
        didSet { UserDefaults.standard.set(todayMinutes, forKey: Keys.todayMinutes) }
    }

    @Published var todayTomatoes: Int {
        didSet { UserDefaults.standard.set(todayTomatoes, forKey: Keys.todayTomatoes) }
    }

    @Published var totalMinutes: Int {
        didSet { UserDefaults.standard.set(totalMinutes, forKey: Keys.totalMinutes) }
    }

    @Published var totalTomatoes: Int {
        didSet { UserDefaults.standard.set(totalTomatoes, forKey: Keys.totalTomatoes) }
    }

    private var targetEndTime: Date?
    private var timerSubscription: Timer?
    private let notificationId = "pomocute_timer_notification"
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .medium)

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    init() {
        let defaults = UserDefaults.standard
        let fM = defaults.integer(forKey: Keys.focusMinutes)
        self.focusMinutes = fM > 0 ? fM : 25

        let sM = defaults.integer(forKey: Keys.shortBreakMinutes)
        self.shortBreakMinutes = sM > 0 ? sM : 5

        let lM = defaults.integer(forKey: Keys.longBreakMinutes)
        self.longBreakMinutes = lM > 0 ? lM : 15

        let cT = defaults.integer(forKey: Keys.cycleTarget)
        self.cycleTarget = cT > 0 ? cT : 4

        self.soundEnabled = defaults.object(forKey: Keys.soundEnabled) == nil ? true : defaults.bool(forKey: Keys.soundEnabled)
        self.hapticEnabled = defaults.object(forKey: Keys.hapticEnabled) == nil ? true : defaults.bool(forKey: Keys.hapticEnabled)

        self.todayMinutes = defaults.integer(forKey: Keys.todayMinutes)
        self.todayTomatoes = defaults.integer(forKey: Keys.todayTomatoes)
        self.totalMinutes = defaults.integer(forKey: Keys.totalMinutes)
        self.totalTomatoes = defaults.integer(forKey: Keys.totalTomatoes)

        checkAndResetDailyStats()
        applyModeDuration(for: .focus)
    }

    deinit {
        timerSubscription?.invalidate()
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
        let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer, forMode: .common)
        timerSubscription = timer
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
        tick()
    }

    private func handleCycleComplete() {
        playChime()
        triggerHaptic()
        checkAndResetDailyStats()

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
        let todayStr = Self.dayFormatter.string(from: Date())
        let lastDate = UserDefaults.standard.string(forKey: Keys.lastDateString) ?? ""
        if lastDate != todayStr {
            todayMinutes = 0
            todayTomatoes = 0
            UserDefaults.standard.set(todayStr, forKey: Keys.lastDateString)
        }
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
        hapticGenerator.prepare()
        hapticGenerator.impactOccurred()
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
