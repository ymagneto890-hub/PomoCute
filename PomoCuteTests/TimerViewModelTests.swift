import XCTest
@testable import PomoCute

final class TimerViewModelTests: XCTestCase {
    private let defaults = UserDefaults.standard
    private let keys = [
        "focusMinutes", "shortBreakMinutes", "longBreakMinutes", "cycleTarget",
        "soundEnabled", "hapticEnabled", "todayMinutes", "todayTomatoes",
        "totalMinutes", "totalTomatoes", "lastDateString", "mode",
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

    func testFormattedTimeUsesMinutesAndSeconds() {
        let viewModel = TimerViewModel()
        viewModel.remainingSeconds = 65
        XCTAssertEqual(viewModel.formattedTime(), "01:05")

        viewModel.remainingSeconds = 0
        XCTAssertEqual(viewModel.formattedTime(), "00:00")
    }

    func testSkippingFocusSessionDoesNotCreditCompletedTomato() {
        let viewModel = TimerViewModel()
        viewModel.skip()

        XCTAssertEqual(viewModel.mode, .shortBreak)
        XCTAssertEqual(viewModel.completedCycles, 0)
        XCTAssertEqual(viewModel.todayTomatoes, 0)
        XCTAssertEqual(viewModel.totalTomatoes, 0)
    }

    func testExpiredPersistedFocusSessionIsCreditedExactlyOnceOnRestore() {
        defaults.set("Enfoque", forKey: "mode")
        defaults.set(60, forKey: "totalSeconds")
        defaults.set(1, forKey: "remainingSeconds")
        defaults.set(4, forKey: "cycleTarget")
        defaults.set(0, forKey: "completedCycles")
        defaults.set(0, forKey: "todayMinutes")
        defaults.set(0, forKey: "todayTomatoes")
        defaults.set(0, forKey: "totalMinutes")
        defaults.set(0, forKey: "totalTomatoes")
        defaults.set(Date().addingTimeInterval(-2).timeIntervalSince1970, forKey: "targetEnd")

        let viewModel = TimerViewModel()

        XCTAssertFalse(viewModel.isRunning)
        XCTAssertEqual(viewModel.mode, .shortBreak)
        XCTAssertEqual(viewModel.completedCycles, 1)
        XCTAssertEqual(viewModel.todayMinutes, 1)
        XCTAssertEqual(viewModel.todayTomatoes, 1)
        XCTAssertEqual(viewModel.totalMinutes, 1)
        XCTAssertEqual(viewModel.totalTomatoes, 1)
    }
}
