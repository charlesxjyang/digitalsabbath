import NetworkExtension
import os.log

class PacketTunnelProvider: NEPacketTunnelProvider {

    private let log = OSLog(subsystem: "com.digitalsabbath.app.PacketTunnel", category: "tunnel")
    private let fakeDNSServer = "198.18.0.1"
    private let tunnelAddress = "198.18.0.2"
    private let upstreamDNS = "1.1.1.1"

    override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        os_log("Starting Sabbath tunnel", log: log, type: .info)

        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: fakeDNSServer)

        let dnsSettings = NEDNSSettings(servers: [fakeDNSServer])
        dnsSettings.matchDomains = [""]
        settings.dnsSettings = dnsSettings

        let ipv4 = NEIPv4Settings(addresses: [tunnelAddress], subnetMasks: ["255.255.255.0"])
        ipv4.includedRoutes = [NEIPv4Route(destinationAddress: fakeDNSServer, subnetMask: "255.255.255.255")]
        settings.ipv4Settings = ipv4
        settings.mtu = 1500 as NSNumber

        setTunnelNetworkSettings(settings) { [weak self] error in
            if let error = error {
                os_log("Tunnel settings failed: %{public}@", log: self?.log ?? .default, type: .error, error.localizedDescription)
                completionHandler(error)
                return
            }

            os_log("Tunnel settings applied, calling completionHandler", log: self?.log ?? .default, type: .info)
            completionHandler(nil)

            // Start reading packets after tunnel is fully established
            self?.readPackets()
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        os_log("Stopping tunnel, reason: %{public}d", log: log, type: .info, reason.rawValue)
        completionHandler()
    }

    // MARK: - Packet Processing

    private func readPackets() {
        packetFlow.readPackets { [weak self] packets, protocols in
            guard let self = self else { return }
            for (i, packet) in packets.enumerated() {
                self.handleDNSPacket(packet, protocolNumber: protocols[i])
            }
            self.readPackets()
        }
    }

    private func handleDNSPacket(_ packet: Data, protocolNumber: NSNumber) {
        guard let (dnsPayload, ihl) = parseDNSFromPacket(packet) else { return }

        if checkIsSabbath(),
           let domain = DNSResolver.extractDomainName(from: dnsPayload),
           BlockedDomains.isBlocked(domain) {
            os_log("Blocking: %{public}@", log: log, type: .info, domain)
            if let blocked = DNSResolver.buildBlockedResponse(for: dnsPayload) {
                sendDNSResponse(blocked, originalPacket: packet, ihl: ihl, protocolNumber: protocolNumber)
            }
            return
        }

        forwardDNS(dnsPayload, originalPacket: packet, ihl: ihl, protocolNumber: protocolNumber)
    }

    private func forwardDNS(_ query: Data, originalPacket: Data, ihl: Int, protocolNumber: NSNumber) {
        let endpoint = NWHostEndpoint(hostname: upstreamDNS, port: "53")
        let session = createUDPSession(to: endpoint, from: nil)

        session.setReadHandler({ [weak self] datagrams, error in
            if let response = datagrams?.first {
                self?.sendDNSResponse(response, originalPacket: originalPacket, ihl: ihl, protocolNumber: protocolNumber)
            }
            session.cancel()
        }, maxDatagrams: 1)

        session.writeDatagram(query) { error in
            if error != nil {
                session.cancel()
            }
        }
    }

    private func sendDNSResponse(_ dnsResponse: Data, originalPacket: Data, ihl: Int, protocolNumber: NSNumber) {
        var ipHeader = Data(originalPacket[0..<ihl])
        let totalLen = UInt16(ihl + 8 + dnsResponse.count)
        ipHeader[2] = UInt8(totalLen >> 8)
        ipHeader[3] = UInt8(totalLen & 0xFF)

        // Swap src/dst IPs
        let src = Data(originalPacket[12..<16])
        let dst = Data(originalPacket[16..<20])
        ipHeader.replaceSubrange(12..<16, with: dst)
        ipHeader.replaceSubrange(16..<20, with: src)

        // Recalc IP checksum
        ipHeader[10] = 0; ipHeader[11] = 0
        let cksum = checksum(ipHeader)
        ipHeader[10] = UInt8(cksum >> 8)
        ipHeader[11] = UInt8(cksum & 0xFF)

        // UDP header: swap ports
        var udp = Data()
        udp.append(originalPacket[ihl + 2]); udp.append(originalPacket[ihl + 3]) // src = old dst
        udp.append(originalPacket[ihl]); udp.append(originalPacket[ihl + 1])     // dst = old src
        let udpLen = UInt16(8 + dnsResponse.count)
        udp.append(UInt8(udpLen >> 8)); udp.append(UInt8(udpLen & 0xFF))
        udp.append(contentsOf: [0, 0]) // checksum

        var response = ipHeader
        response.append(udp)
        response.append(dnsResponse)

        packetFlow.writePackets([response], withProtocols: [protocolNumber])
    }

    // MARK: - Helpers

    private func parseDNSFromPacket(_ packet: Data) -> (Data, Int)? {
        guard packet.count > 28 else { return nil }
        let ihl = Int(packet[0] & 0x0F) * 4
        guard ihl >= 20, packet.count > ihl + 8 else { return nil }
        guard packet[9] == 17 else { return nil } // UDP only
        let dstPort = UInt16(packet[ihl + 2]) << 8 | UInt16(packet[ihl + 3])
        guard dstPort == 53 else { return nil }
        let start = ihl + 8
        guard start < packet.count else { return nil }
        return (Data(packet[start...]), ihl)
    }

    private func checksum(_ data: Data) -> UInt16 {
        var sum: UInt32 = 0
        var i = 0
        while i < data.count - 1 {
            sum += UInt32(data[i]) << 8 | UInt32(data[i + 1])
            i += 2
        }
        if data.count % 2 == 1 { sum += UInt32(data[data.count - 1]) << 8 }
        while sum >> 16 != 0 { sum = (sum & 0xFFFF) + (sum >> 16) }
        return ~UInt16(sum & 0xFFFF)
    }

    private func checkIsSabbath() -> Bool {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return ["2026-02-16", "2026-06-21"].contains(f.string(from: Date()))
    }
}
