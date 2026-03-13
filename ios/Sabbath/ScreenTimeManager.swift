import Foundation
import Combine
import FamilyControls
import ManagedSettings
import DeviceActivity
import os.log

class ScreenTimeManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var isBlocking = false
    @Published var isPreviewActive = false
    @Published var activitySelection = FamilyActivitySelection()

    var hasSelection: Bool {
        !activitySelection.applicationTokens.isEmpty || !activitySelection.categoryTokens.isEmpty
    }

    private let store = ManagedSettingsStore()
    private let center = DeviceActivityCenter()
    private let log = OSLog(subsystem: "com.digitalsabbath.app", category: "screentime")
    private var previewStopWork: DispatchWorkItem?

    private static let appGroupDefaults = UserDefaults(suiteName: "group.com.digitalsabbath.app")

    init() {
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
        loadSelection()
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            await MainActor.run {
                self.isAuthorized = true
            }
        } catch {
            os_log("FamilyControls authorization failed: %{public}@", log: log, type: .error, error.localizedDescription)
        }
    }

    // MARK: - Selection Persistence

    func saveSelection() {
        guard let defaults = Self.appGroupDefaults else { return }
        do {
            let data = try PropertyListEncoder().encode(activitySelection)
            defaults.set(data, forKey: "activitySelection")
        } catch {
            os_log("Failed to save selection: %{public}@", log: log, type: .error, error.localizedDescription)
        }
    }

    func loadSelection() {
        guard let defaults = Self.appGroupDefaults,
              let data = defaults.data(forKey: "activitySelection") else { return }
        do {
            activitySelection = try PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
        } catch {
            os_log("Failed to load selection: %{public}@", log: log, type: .error, error.localizedDescription)
        }
    }

    // MARK: - Blocking

    func startBlocking() {
        guard hasSelection else { return }
        store.shield.applications = activitySelection.applicationTokens.isEmpty ? nil : activitySelection.applicationTokens
        store.shield.applicationCategories = activitySelection.categoryTokens.isEmpty
            ? nil
            : .specific(activitySelection.categoryTokens)
        isBlocking = true
    }

    func stopBlocking() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        isBlocking = false
    }

    // MARK: - Preview

    func startPreview() {
        startBlocking()
        isPreviewActive = true

        let stopWork = DispatchWorkItem { [weak self] in
            self?.stopPreview()
        }
        previewStopWork = stopWork
        DispatchQueue.main.asyncAfter(deadline: .now() + 3600, execute: stopWork)
    }

    func stopPreview() {
        previewStopWork?.cancel()
        previewStopWork = nil
        stopBlocking()
        DispatchQueue.main.async {
            self.isPreviewActive = false
        }
    }

    // MARK: - Sabbath Scheduling

    func scheduleSabbathBlocking() {
        guard hasSelection else { return }

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
            repeats: true
        )

        do {
            try center.startMonitoring(
                DeviceActivityName("sabbath"),
                during: schedule
            )
        } catch {
            os_log("Failed to schedule sabbath blocking: %{public}@", log: log, type: .error, error.localizedDescription)
        }
    }
}
