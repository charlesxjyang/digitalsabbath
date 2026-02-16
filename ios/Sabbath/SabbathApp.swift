import SwiftUI

@main
struct SabbathApp: App {
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
                    }
            } else {
                OnboardingView(vpnManager: vpnManager, hasOnboarded: $hasOnboarded)
            }
        }
    }
}
