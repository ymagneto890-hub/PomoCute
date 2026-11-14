import XCTest
@testable import PomoCute

final class TimerViewModelTests: XCTestCase {
    private let defaults = UserDefaults.standard
    private let keys = [
        "focusMinutes", "shortBreakMinutes", "longBreakMinutes", "cycleTarget",
        "soundEnabled", "hapticEnabled", "todayMinutes",
        "totalMinutes", "dailyMinutesHistory", "lastDateString", "mode",
        "totalSeconds", "remainingSeconds", "completedCycles", "targetEnd"
    ]

    override func setUp() {
        super.setUp()
        keys.forEach { defaults.removeObject(forKey: $0) }
        defaults.set(todayString(), forKey: "lastDateString")
        defaults.set(false, forKey: "soundEnabled")
        defaults.set(false, forKey: "hapticEnabled")
    }

    override func tearDown() {
        keys.forEach { defaults.removeObject(forKey: $0) }
        super.tearDown()
    }

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }

    func testDefaultTimerStartsAtTwentyFiveMinutes() {
        let viewModel = TimerViewModel()

        XCTAssertEqual(viewModel.mode, .focus)
        XCTAssertEqual(viewModel.totalSeconds, 25 * 60)
        XCTAssertEqual(viewModel.remainingSeconds, 25 * 60)
        XCTAssertFalse(viewModel.isRunning)
    }

    func testChangingModeLoadsTheCorrectDuration() {
        defaults.set(25, forKey: "focusMinutes")
        defaults.set(5, forKey: "shortBreakMinutes")
        defaults.set(15, forKey: "longBreakMinutes")
        let viewModel = TimerViewModel()

        viewModel.setMode(.shortBreak)
        XCTAssertEqual(viewModel.mode, .shortBreak)
        XCTAssertEqual(viewModel.totalSeconds, 5 * 60)
        XCTAssertEqual(viewModel.remainingSeconds, 5 * 60)

        viewModel.setMode(.longBreak)
        XCTAssertEqual(viewModel.mode, .longBreak)
        XCTAssertEqual(viewModel.totalSeconds, 15 * 60)
        XCTAssertEqual(viewModel.remainingSeconds, 15 * 60)
    }

    func testResetRestoresSelectedModeDuration() {
        let viewModel = TimerViewModel()
        viewModel.remainingSeconds = 37
        viewModel.reset()

        XCTAssertEqual(viewModel.remainingSeconds, viewModel.totalSeconds)
        XCTAssertFalse(viewModel.isRunning)
    }

    func testPauseStopsRunningTimerAndPreservesPositiveTime() {
        let viewModel = TimerViewModel()
        viewModel.start()
        XCTAssertTrue(viewModel.isRunning)

        viewModel.pause()

        XCTAssertFalse(viewModel.isRunning)
        XCTAssertGreaterThan(viewModel.remainingSeconds, 0)
        XCTAssertLessThanOrEqual(viewModel.remainingSeconds, viewModel.totalSeconds)
    }

    func testPauseAndResumeDoNotRestartTheFullSession() {
        let viewModel = TimerViewModel()
        viewModel.remainingSeconds = 120
        viewModel.start()
        viewModel.pause()
        let pausedSeconds = viewModel.remainingSeconds

        XCTAssertFalse(viewModel.isRunning)
        XCTAssertGreaterThan(pausedSeconds, 0)
        XCTAssertLessThanOrEqual(pausedSeconds, 120)
        XCTAssertEqual(defaults.double(forKey: "targetEnd"), 0)

        viewModel.start()
        XCTAssertTrue(viewModel.isRunning)
        XCTAssertLessThanOrEqual(viewModel.remainingSeconds, pausedSeconds)
        viewModel.pause()
    }

    func testNuevoDiaReiniciaSoloLasEstadisticasDiariasYCiclosConservandoHistorial() {
        defaults.set("Enfoque", forKey: "mode")
        defaults.set(1500, forKey: "totalSeconds")
        defaults.set(900, forKey: "remainingSeconds")
        defaults.set("2000-01-01", forKey: "lastDateString")
        defaults.set(3, forKey: "completedCycles")
        defaults.set(45, forKey: "todayMinutes")
        defaults.set(600, forKey: "totalMinutes")

        let viewModel = TimerViewModel()

        XCTAssertEqual(viewModel.todayMinutes, 0)
        XCTAssertEqual(viewModel.completedCycles, 0)
        XCTAssertEqual(viewModel.totalMinutes, 600)
        XCTAssertEqual(viewModel.dailyMinutesHistory["2000-01-01"], 45)
        XCTAssertEqual(viewModel.remainingSeconds, 900)
    }

    func testDescansoExpiradoAlRestaurarNoCuentaMinutos() {
        defaults.set("Corto", forKey: "mode")
        defaults.set(300, forKey: "totalSeconds")
        defaults.set(1, forKey: "remainingSeconds")
        defaults.set(2, forKey: "completedCycles")
        defaults.set(17, forKey: "todayMinutes")
        defaults.set(100, forKey: "totalMinutes")
        defaults.set(Date().addingTimeInterval(-2).timeIntervalSince1970, forKey: "targetEnd")

        let viewModel = TimerViewModel()

        XCTAssertEqual(viewModel.mode, .focus)
        XCTAssertFalse(viewModel.isRunning)
        XCTAssertEqual(viewModel.completedCycles, 2)
        XCTAssertEqual(viewModel.todayMinutes, 17)
        XCTAssertEqual(viewModel.totalMinutes, 100)
    }

    func testFormattedTimeUsesMinutesAndSeconds() {
        let viewModel = TimerViewModel()
        viewModel.remainingSeconds = 65
        XCTAssertEqual(viewModel.formattedTime(), "01:05")

        viewModel.remainingSeconds = 0
        XCTAssertEqual(viewModel.formattedTime(), "00:00")
    }

    func testSkippingFocusSessionDoesNotCreditCompletedCycleOrMinutes() {
        let viewModel = TimerViewModel()
        viewModel.skip()

        XCTAssertEqual(viewModel.mode, .shortBreak)
        XCTAssertEqual(viewModel.completedCycles, 0)
        XCTAssertEqual(viewModel.todayMinutes, 0)
        XCTAssertEqual(viewModel.totalMinutes, 0)
    }

    func testExpiredPersistedFocusSessionIsCreditedExactlyOnceOnRestore() {
        defaults.set("Enfoque", forKey: "mode")
        defaults.set(60, forKey: "totalSeconds")
        defaults.set(1, forKey: "remainingSeconds")
        defaults.set(4, forKey: "cycleTarget")
        defaults.set(0, forKey: "completedCycles")
        defaults.set(0, forKey: "todayMinutes")
        defaults.set(0, forKey: "totalMinutes")
        defaults.set(Date().addingTimeInterval(-2).timeIntervalSince1970, forKey: "targetEnd")

        let viewModel = TimerViewModel()

        XCTAssertFalse(viewModel.isRunning)
        XCTAssertEqual(viewModel.mode, .shortBreak)
        XCTAssertEqual(viewModel.completedCycles, 1)
        XCTAssertEqual(viewModel.todayMinutes, 1)
        XCTAssertEqual(viewModel.totalMinutes, 1)
    }

    func testCurrentWeekDaysReturnsSevenDaysFromMondayToSunday() {
        let viewModel = TimerViewModel()
        viewModel.todayMinutes = 90

        let days = viewModel.currentWeekDays()
        XCTAssertEqual(days.count, 7)
        XCTAssertEqual(days.map(\.shortLabel), ["L", "M", "X", "J", "V", "S", "D"])
        XCTAssertEqual(days.filter(\.isToday).count, 1)
        XCTAssertEqual(days.first(where: \.isToday)?.minutes, 90)
        XCTAssertGreaterThanOrEqual(viewModel.weekMinutes, 90)
    }

    func testRecentWeeksBarsReturnsFiveWeeksEndingInCurrent() {
        let viewModel = TimerViewModel()
        viewModel.todayMinutes = 120

        let weeks = viewModel.recentWeeksBars()
        XCTAssertEqual(weeks.count, 5)
        XCTAssertEqual(weeks.last?.shortLabel, "Actual")
        XCTAssertEqual(weeks.last?.isToday, true)
        XCTAssertGreaterThanOrEqual(weeks.last?.minutes ?? 0, 120)
        XCTAssertEqual(weeks.filter(\.isToday).count, 1)
        XCTAssertEqual(viewModel.chartMaxAxisHours(for: weeks, minimumHours: 16), 16)
        XCTAssertGreaterThanOrEqual(viewModel.recentWeeksMinutes, 120)
    }

    func testBarFormattingAndAxisScaling() {
        let viewModel = TimerViewModel()
        XCTAssertEqual(viewModel.formatShortBarValue(0), "")
        XCTAssertEqual(viewModel.formatShortBarValue(45), "45m")
        XCTAssertEqual(viewModel.formatShortBarValue(120), "2h")
        XCTAssertEqual(viewModel.formatShortBarValue(150), "2.5h")

        let sampleLow = [DayBarData(id: "2026-11-09", shortLabel: "L", minutes: 120, isToday: true)]
        XCTAssertEqual(viewModel.chartMaxAxisHours(for: sampleLow), 4)

        let sampleHigh = [DayBarData(id: "2026-11-09", shortLabel: "L", minutes: 300, isToday: true)]
        XCTAssertEqual(viewModel.chartMaxAxisHours(for: sampleHigh), 8)
    }
}
