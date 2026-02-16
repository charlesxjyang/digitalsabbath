import NetworkExtension
import os.log

class VPNManager: ObservableObject {
    @Published var isConnected = false
    @Published var isInstalled = false

    private let log = OSLog(subsystem: "com.digitalsabbath.app", category: "vpn")

    init() {
        loadFromPreferences()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(vpnStatusChanged),
            name: .NEVPNStatusDidChange,
            object: nil
        )
    }

    func loadFromPreferences() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            DispatchQueue.main.async {
                if let manager = managers?.first {
                    self?.isInstalled = true
                    self?.isConnected = manager.connection.status == .connected
                }
            }
        }
    }

    func installAndEnable(completion: @escaping (Bool) -> Void) {
        let manager = NETunnelProviderManager()
        let proto = NETunnelProviderProtocol()

        proto.providerBundleIdentifier = "com.digitalsabbath.app.PacketTunnel"
        proto.serverAddress = "Sabbath Local"
        proto.disconnectOnSleep = false

        manager.protocolConfiguration = proto
        manager.localizedDescription = "Sabbath"
        manager.isEnabled = true

        manager.saveToPreferences { [weak self] error in
            if let error = error {
                os_log("Failed to save VPN: %{public}@", log: self?.log ?? .default, type: .error, error.localizedDescription)
                DispatchQueue.main.async { completion(false) }
                return
            }

            // Reload after save
            manager.loadFromPreferences { error in
                if let error = error {
                    os_log("Failed to reload VPN: %{public}@", log: self?.log ?? .default, type: .error, error.localizedDescription)
                    DispatchQueue.main.async { completion(false) }
                    return
                }

                DispatchQueue.main.async {
                    self?.isInstalled = true
                    completion(true)
                }

                // Start the tunnel
                do {
                    try manager.connection.startVPNTunnel()
                    DispatchQueue.main.async {
                        self?.isConnected = true
                    }
                } catch {
                    os_log("Failed to start tunnel: %{public}@", log: self?.log ?? .default, type: .error, error.localizedDescription)
                }
            }
        }
    }

    func startTunnel() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            guard let manager = managers?.first else { return }
            do {
                try manager.connection.startVPNTunnel()
                DispatchQueue.main.async {
                    self?.isConnected = true
                }
            } catch {
                os_log("Failed to start tunnel: %{public}@", type: .error, error.localizedDescription)
            }
        }
    }

    func stopTunnel() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            guard let manager = managers?.first else { return }
            manager.connection.stopVPNTunnel()
            DispatchQueue.main.async {
                self?.isConnected = false
            }
        }
    }

    @objc private func vpnStatusChanged(_ notification: Notification) {
        guard let connection = notification.object as? NEVPNConnection else { return }
        DispatchQueue.main.async {
            self.isConnected = connection.status == .connected
        }
    }
}
