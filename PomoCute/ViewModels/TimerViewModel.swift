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
        static let mode = "mode"
        static let totalSeconds = "totalSeconds"
        static let remainingSeconds = "remainingSeconds"
        static let completedCycles = "completedCycles"
        static let targetEnd = "targetEnd"
    }

    // MARK: - Estado de Temporizador Reactivo
    @Published var mode: PomodoroMode = .focus
    @Published var isRunning: Bool = false
    @Published var remainingSeconds: Int = 25 * 60
    @Published var totalSeconds: Int = 25 * 60
    @Published var completedCycles: Int = 0 {
        didSet {
            UserDefaults.standard.set(completedCycles, forKey: Keys.completedCycles)
        }
    }
    @Published var notificationsDenied: Bool = false
    @Published var showingCompletionAlert: Bool = false
    @Published var completionAlertMessage: String = ""

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
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: Keys.soundEnabled)
            // Si el temporizador está corriendo y cambia el sonido, actualizar la notificación pendiente
            if isRunning, let target = targetEndTime {
                let remaining = Int(ceil(target.timeIntervalSinceNow))
                if remaining > 0 {
                    scheduleNativeAlarm(seconds: remaining)
                }
            }
        }
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

    // Recursos de sonido del bundle (.caf)
    private var popSoundID: SystemSoundID = 0
    private var bellSoundID: SystemSoundID = 0

    // Observador de cambio de día a medianoche
    private var dayChangeObserver: NSObjectProtocol?

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
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

        if let savedModeStr = defaults.string(forKey: Keys.mode), let savedMode = PomodoroMode(rawValue: savedModeStr) {
            self.mode = savedMode
        } else {
            self.mode = .focus
        }
        self.completedCycles = defaults.integer(forKey: Keys.completedCycles)
        let savedTotalSeconds = defaults.integer(forKey: Keys.totalSeconds)
        let savedRemainingSeconds = defaults.integer(forKey: Keys.remainingSeconds)

        checkAndResetDailyStats()

        if savedTotalSeconds > 0 {
            self.totalSeconds = savedTotalSeconds
            self.remainingSeconds = savedRemainingSeconds > 0 ? savedRemainingSeconds : savedTotalSeconds
        } else {
            applyModeDuration(for: mode)
        }

        let savedTargetEnd = defaults.double(forKey: Keys.targetEnd)
        if savedTargetEnd > 0 {
            let targetDate = Date(timeIntervalSince1970: savedTargetEnd)
            if targetDate > Date() {
                self.targetEndTime = targetDate
                self.isRunning = true
                self.remainingSeconds = Int(ceil(targetDate.timeIntervalSinceNow))
                startTicking()
            } else {
                finishCycle(credited: true, alert: false)
            }
        }

        loadCustomSounds()
        setupDayChangeObserver()
    }

    deinit {
        timerSubscription?.invalidate()
        if let observer = dayChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if popSoundID != 0 {
            AudioServicesDisposeSystemSoundID(popSoundID)
        }
        if bellSoundID != 0 {
            AudioServicesDisposeSystemSoundID(bellSoundID)
        }
    }

    // MARK: - Carga de Sonidos Propios
    private func loadCustomSounds() {
        if let popURL = soundResourceURL(named: "pop") {
            AudioServicesCreateSystemSoundID(popURL as CFURL, &popSoundID)
        }
        if let bellURL = soundResourceURL(named: "bell") {
            AudioServicesCreateSystemSoundID(bellURL as CFURL, &bellSoundID)
        }
    }

    private func soundResourceURL(named name: String) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: "caf") {
            return url
        }
        return Bundle.main.url(forResource: name, withExtension: "caf", subdirectory: "Audio")
    }

    // MARK: - Observador de Cambio de Fecha (Medianoche)
    private func setupDayChangeObserver() {
        dayChangeObserver = NotificationCenter.default.addObserver(
            forName: .NSCalendarDayChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkAndResetDailyStats()
        }
    }

    // MARK: - Persistencia de Estado del Temporizador
    private func persistTimerState() {
        let defaults = UserDefaults.standard
        defaults.set(mode.rawValue, forKey: Keys.mode)
        defaults.set(totalSeconds, forKey: Keys.totalSeconds)
        defaults.set(remainingSeconds, forKey: Keys.remainingSeconds)
        defaults.set(completedCycles, forKey: Keys.completedCycles)
        defaults.set(targetEndTime?.timeIntervalSince1970 ?? 0, forKey: Keys.targetEnd)
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
        startTicking()
        persistTimerState()

        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            if settings.authorizationStatus == .denied {
                DispatchQueue.main.async {
                    self?.notificationsDenied = true
                }
            }
        }
    }

    func pause() {
        isRunning = false
        targetEndTime = nil
        timerSubscription?.invalidate()
        timerSubscription = nil
        cancelNativeAlarm()
        persistTimerState()
    }

    func reset() {
        playPop()
        pause()
        applyModeDuration(for: mode)
    }

    func skip() {
        playPop()
        pause()
        finishCycle(credited: false, alert: false)
    }

    private func switchMode(_ newMode: PomodoroMode) {
        pause()
        mode = newMode
        applyModeDuration(for: newMode)
    }

    func setMode(_ newMode: PomodoroMode) {
        guard mode != newMode else { return }
        playPop()
        switchMode(newMode)
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
        persistTimerState()
    }

    private func startTicking() {
        timerSubscription?.invalidate()
        guard let target = targetEndTime else { return }
        let secs = target.timeIntervalSinceNow
        guard secs > 0 else { tick(); return }
        let first = target.addingTimeInterval(-(ceil(secs) - 1))   // próximo cambio real de segundo
        let t = Timer(fire: first, interval: 1.0, repeats: true) { [weak self] _ in self?.tick() }
        t.tolerance = 0.1
        RunLoop.main.add(t, forMode: .common)
        timerSubscription = t
    }

    private func tick(alertOnFinish: Bool = true) {
        guard isRunning, let target = targetEndTime else { return }
        let diff = Int(ceil(target.timeIntervalSinceNow))
        if diff <= 0 {
            remainingSeconds = 0
            pause()
            finishCycle(credited: true, alert: alertOnFinish)
        } else if diff != remainingSeconds {
            remainingSeconds = diff
        }
    }

    func appDidEnterBackground() {
        timerSubscription?.invalidate()
        timerSubscription = nil
    }

    func appWillResignActive() {
        persistTimerState()
    }

    func appDidBecomeActive() {
        checkAndResetDailyStats()
        tick(alertOnFinish: false)
        if isRunning {
            startTicking()
        }
    }

    private func finishCycle(credited: Bool, alert: Bool) {
        if alert {
            playChime()
            triggerHaptic()
            completionAlertMessage = (mode == .focus)
                ? "¡Sesión de Enfoque completada! Toca descansar un ratito 🍵"
                : "¡Descanso terminado! Listo para concentrarte 🍅"
            showingCompletionAlert = true
        }
        cancelNativeAlarm()
        checkAndResetDailyStats()

        if mode == .focus {
            if credited {
                let minutesToAdd = totalSeconds / 60
                todayMinutes += minutesToAdd
                todayTomatoes += 1
                totalMinutes += minutesToAdd
                totalTomatoes += 1
                completedCycles += 1

                if completedCycles % cycleTarget == 0 {
                    switchMode(.longBreak)
                } else {
                    switchMode(.shortBreak)
                }
            } else {
                switchMode(.shortBreak)
            }
        } else {
            switchMode(.focus)
        }
        persistTimerState()
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
            completedCycles = 0
            UserDefaults.standard.set(0, forKey: Keys.completedCycles)
            UserDefaults.standard.set(todayStr, forKey: Keys.lastDateString)
        }
    }

    // MARK: - Notificaciones Nativas del Sistema
    private func scheduleNativeAlarm(seconds: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationId])
        center.removeDeliveredNotifications(withIdentifiers: [notificationId])

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
        content.sound = soundEnabled ? .default : nil

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(max(1, seconds)), repeats: false)
        let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                #if DEBUG
                print("[PomoCute] Error al programar la notificación: \(error.localizedDescription)")
                #endif
            }
        }
    }

    private func cancelNativeAlarm() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationId])
        center.removeDeliveredNotifications(withIdentifiers: [notificationId])
    }

    // MARK: - Sonidos y Hápticos
    func playPop() {
        guard soundEnabled else { return }
        if popSoundID != 0 {
            AudioServicesPlaySystemSound(popSoundID)
        }
    }

    func playChime() {
        guard soundEnabled else { return }
        if bellSoundID != 0 {
            AudioServicesPlaySystemSound(bellSoundID)
        }
    }

    func triggerHaptic() {
        guard hapticEnabled else { return }
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
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
