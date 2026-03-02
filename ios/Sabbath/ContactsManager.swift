import Contacts
import CryptoKit
import Foundation
import os.log

struct ContactMatch: Codable, Identifiable {
    let hash: String
    let name: String
    var id: String { hash }
}

enum ContactsManager {
    static func requestAccess() async -> Bool {
        let store = CNContactStore()
        do {
            return try await store.requestAccess(for: .contacts)
        } catch {
            os_log("Contacts access request failed: %{public}@", type: .error, error.localizedDescription)
            return false
        }
    }

    static func fetchContactPhoneHashes() -> [ContactMatch] {
        let store = CNContactStore()
        let keys: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
        ]

        var results: [ContactMatch] = []
        var seenHashes = Set<String>()

        let request = CNContactFetchRequest(keysToFetch: keys)
        do {
            try store.enumerateContacts(with: request) { contact, _ in
                let name = [contact.givenName, contact.familyName]
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                guard !name.isEmpty else { return }

                for phoneNumber in contact.phoneNumbers {
                    let raw = phoneNumber.value.stringValue
                    if let normalized = normalizePhoneNumber(raw) {
                        let hash = sha256(normalized)
                        if seenHashes.insert(hash).inserted {
                            results.append(ContactMatch(hash: hash, name: name))
                        }
                    }
                }
            }
        } catch {
            os_log("Failed to fetch contacts: %{public}@", type: .error, error.localizedDescription)
        }

        return results
    }

    static func normalizePhoneNumber(_ raw: String) -> String? {
        let digits = raw.unicodeScalars.filter { CharacterSet.decimalDigits.contains($0) }
        let cleaned = String(digits)
        guard cleaned.count >= 7 else { return nil }

        if raw.hasPrefix("+") {
            return "+" + cleaned
        }

        // Default to US +1 if no country code
        if cleaned.count == 10 {
            return "+1" + cleaned
        }
        if cleaned.count == 11 && cleaned.hasPrefix("1") {
            return "+" + cleaned
        }

        return "+" + cleaned
    }

    static func hashPhoneNumber(_ phoneNumber: String) -> String? {
        guard let normalized = normalizePhoneNumber(phoneNumber) else { return nil }
        return sha256(normalized)
    }

    private static func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
