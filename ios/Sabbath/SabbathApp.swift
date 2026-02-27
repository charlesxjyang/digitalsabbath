import SwiftUI
import UserNotifications
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UIApplication.shared.registerForRemoteNotifications()
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set(token, forKey: "apnsToken")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("APNs registration failed: \(error.localizedDescription)")
    }
}

@main
struct SabbathApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var vpnManager = VPNManager()
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some Scene {
        WindowGroup {
            if hasOnboarded {
                ContentView(vpnManager: vpnManager)
                    .onAppear {
                        if SabbathSchedule.isSabbathActive() && !vpnManager.isConnected {
                            vpnManager.startTunnel()
                        }
                        scheduleSabbathNotifications()
                    }
            } else {
                OnboardingView(vpnManager: vpnManager, hasOnboarded: $hasOnboarded)
            }
        }
    }

    private func scheduleSabbathNotifications() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            center.removeAllPendingNotificationRequests()

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = .current

            for dateString in SabbathSchedule.sabbathDates {
                guard let date = formatter.date(from: dateString) else { continue }

                // Morning notification at 8am on sabbath day
                let morningContent = UNMutableNotificationContent()
                morningContent.title = "Digital Sabbath has begun"
                morningContent.body = "Today we rest together. Your distracting apps are being blocked."
                morningContent.sound = .default

                var morningComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
                morningComponents.hour = 8
                morningComponents.minute = 0
                let morningTrigger = UNCalendarNotificationTrigger(dateMatching: morningComponents, repeats: false)
                let morningRequest = UNNotificationRequest(
                    identifier: "sabbath-morning-\(dateString)",
                    content: morningContent,
                    trigger: morningTrigger
                )
                center.add(morningRequest)

                // Day-before reminder at 8pm
                if let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: date) {
                    let reminderContent = UNMutableNotificationContent()
                    reminderContent.title = "Digital Sabbath is tomorrow"
                    reminderContent.body = "Tomorrow we all put down our phones together. Get ready."
                    reminderContent.sound = .default

                    var reminderComponents = Calendar.current.dateComponents([.year, .month, .day], from: dayBefore)
                    reminderComponents.hour = 20
                    reminderComponents.minute = 0
                    let reminderTrigger = UNCalendarNotificationTrigger(dateMatching: reminderComponents, repeats: false)
                    let reminderRequest = UNNotificationRequest(
                        identifier: "sabbath-reminder-\(dateString)",
                        content: reminderContent,
                        trigger: reminderTrigger
                    )
                    center.add(reminderRequest)
                }
            }
        }
    }
}
