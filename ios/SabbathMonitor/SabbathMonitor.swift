import DeviceActivity
import ManagedSettings
import Foundation

class SabbathMonitor: DeviceActivityMonitor {

    let store = ManagedSettingsStore()
    let appGroupID = "group.com.digitalsabbath.app"

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        applyShields()
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        store.clearAllSettings()
    }

    private func applyShields() {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: "blockedApps"),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else { return }

        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = .specific(selection.categoryTokens)
    }
}
