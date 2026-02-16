import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

class ScreenTimeManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var activitySelection = FamilyActivitySelection()

    static let shared = ScreenTimeManager()

    private let center = AuthorizationCenter.shared
    private let store = ManagedSettingsStore()
    private let activityCenter = DeviceActivityCenter()

    private let appGroupID = "group.com.digitalsabbath.app"

    init() {
        isAuthorized = center.authorizationStatus == .approved
    }

    func requestAuthorization() async {
        do {
            try await center.requestAuthorization(for: .individual)
            await MainActor.run {
                isAuthorized = true
            }
        } catch {
            await MainActor.run {
                isAuthorized = false
            }
        }
    }

    func saveSelection() {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        if let encoded = try? JSONEncoder().encode(activitySelection) {
            defaults.set(encoded, forKey: "blockedApps")
        }
    }

    func loadSelection() {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: "blockedApps"),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else { return }
        activitySelection = selection
    }

    func scheduleSabbath(for dateString: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        guard let date = formatter.date(from: dateString) else { return }

        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)

        guard let endDate = calendar.date(byAdding: .day, value: 1, to: date) else { return }
        let endComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: endDate)

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: startComponents.hour, minute: startComponents.minute),
            intervalEnd: DateComponents(hour: endComponents.hour, minute: endComponents.minute),
            repeats: false
        )

        let activityName = DeviceActivityName("sabbath-\(dateString)")
        do {
            try activityCenter.startMonitoring(activityName, during: schedule)
        } catch {
            // Monitor scheduling failed
        }
    }

    func applyShieldsNow() {
        store.shield.applications = activitySelection.applicationTokens
        store.shield.applicationCategories = .specific(activitySelection.categoryTokens)
    }

    func removeShields() {
        store.clearAllSettings()
    }

    func scheduleAllSabbaths() {
        for dateString in SabbathSchedule.sabbathDates {
            scheduleSabbath(for: dateString)
        }
    }
}
