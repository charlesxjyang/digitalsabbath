import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

@main
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    static func main() {
        dispatchMain()
    }

    let store = ManagedSettingsStore()

    private static let sabbathDates: Set<String> = [
        "2026-06-21",
    ]

    private func isSabbathToday() -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return Self.sabbathDates.contains(formatter.string(from: Date()))
    }

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        guard activity.rawValue == "sabbath" else { return }
        guard isSabbathToday() else { return }

        guard let defaults = UserDefaults(suiteName: "group.com.digitalsabbath.app"),
              let data = defaults.data(forKey: "activitySelection"),
              let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) else {
            return
        }

        if !selection.applicationTokens.isEmpty {
            store.shield.applications = selection.applicationTokens
        }
        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(selection.categoryTokens)
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        guard activity.rawValue == "sabbath" else { return }

        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }
}
