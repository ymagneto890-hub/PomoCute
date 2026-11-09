import SwiftUI
import UserNotifications

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Con la app en primer plano, el aviso lo gestiona la propia interfaz de la app
        completionHandler([])
    }
}

@main
struct PomoCuteApp: App {
    @StateObject private var timerVM = TimerViewModel()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let center = UNUserNotificationCenter.current()
        center.delegate = NotificationDelegate.shared
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(timerVM)
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                timerVM.appDidBecomeActive()
            case .inactive:
                timerVM.appWillResignActive()
            case .background:
                timerVM.appDidEnterBackground()
            @unknown default:
                break
            }
        }
    }
}
