import SwiftUI
import UserNotifications

@main
struct PomoCuteApp: App {
    @StateObject private var timerVM = TimerViewModel()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        requestNotificationPermission()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(timerVM)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                timerVM.appDidBecomeActive()
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
}
