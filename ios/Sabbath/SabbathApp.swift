import SwiftUI
import FamilyControls

@main
struct SabbathApp: App {
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some Scene {
        WindowGroup {
            if hasOnboarded {
                ContentView(screenTimeManager: screenTimeManager)
                    .onAppear {
                        screenTimeManager.loadSelection()
                        if SabbathSchedule.isSabbathActive() {
                            screenTimeManager.applyShieldsNow()
                        }
                        screenTimeManager.scheduleAllSabbaths()
                    }
            } else {
                OnboardingView(screenTimeManager: screenTimeManager, hasOnboarded: $hasOnboarded)
            }
        }
    }
}
