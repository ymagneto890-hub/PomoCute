import SwiftUI
import UserNotifications

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Permite que la notificación suene y muestre banner incluso si la app está abierta en pantalla
        completionHandler([.banner, .sound, .badge])
    }
}

@main
struct PomoCuteApp: App {
    @StateObject private var timerVM = TimerViewModel()
    @Environment(\.scenePhase) private var scenePhase
    private let notificationDelegate = NotificationDelegate()

    init() {
        let center = UNUserNotificationCenter.current()
        center.delegate = notificationDelegate
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
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
}
