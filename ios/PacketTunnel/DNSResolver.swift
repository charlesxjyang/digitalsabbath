import Foundation

struct DNSResolver {

    // MARK: - Parse a DNS query and extract the domain name

    static func extractDomainName(from packet: Data) -> String? {
        // DNS header is 12 bytes
        guard packet.count > 12 else { return nil }

        var offset = 12
        var labels: [String] = []

        while offset < packet.count {
            let length = Int(packet[offset])
            if length == 0 { break }
            offset += 1
            guard offset + length <= packet.count else { return nil }
            let label = packet[offset..<offset + length]
            if let s = String(bytes: label, encoding: .ascii) {
                labels.append(s)
            }
            offset += length
        }

        return labels.isEmpty ? nil : labels.joined(separator: ".")
    }

    // MARK: - Build a spoofed DNS response returning 0.0.0.0

    static func buildBlockedResponse(for query: Data) -> Data? {
        guard query.count > 12 else { return nil }

        var response = Data(query)

        // Set QR bit (response), recursion available
        response[2] = 0x81
        response[3] = 0x80

        // Set answer count to 1
        response[4] = 0x00
        response[5] = 0x01 // QDCOUNT stays as-is from query
        response[6] = 0x00
        response[7] = 0x01 // ANCOUNT = 1

        // Zero out NSCOUNT and ARCOUNT
        response[8] = 0x00
        response[9] = 0x00
        response[10] = 0x00
        response[11] = 0x00

        // Preserve QDCOUNT from query
        response[4] = query[4]
        response[5] = query[5]

        // Answer section: pointer to name in question, type A, class IN, TTL 60, 0.0.0.0
        var answer = Data()
        answer.append(contentsOf: [0xC0, 0x0C])       // Name pointer to offset 12
        answer.append(contentsOf: [0x00, 0x01])       // Type A
        answer.append(contentsOf: [0x00, 0x01])       // Class IN
        answer.append(contentsOf: [0x00, 0x00, 0x00, 0x3C]) // TTL 60s
        answer.append(contentsOf: [0x00, 0x04])       // RDLENGTH 4
        answer.append(contentsOf: [0x00, 0x00, 0x00, 0x00]) // 0.0.0.0

        response.append(answer)

        return response
    }
}
