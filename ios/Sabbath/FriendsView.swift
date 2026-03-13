import MessageUI
import SwiftUI
import os.log

struct FriendsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var phoneNumber: String = UserDefaults.standard.string(forKey: "userPhoneNumber") ?? ""
    @State private var matchedFriends: [ContactMatch] = []
    @State private var isLoading = false
    @State private var hasSearched = UserDefaults.standard.bool(forKey: "hasSearchedFriends")
    @State private var showMessageComposer = false
    @State private var errorMessage: String?

    private static let apiBase = "https://digital-sabbath-api.charlesxjyang.workers.dev"

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.96, green: 0.94, blue: 0.90)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        if !hasSearched {
                            phoneInputSection
                        } else if isLoading {
                            loadingSection
                        } else {
                            resultsSection
                        }
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, 24)
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundColor(.black)
                }
            }
        }
        .onAppear { loadCachedResults() }
        .sheet(isPresented: $showMessageComposer) {
            MessageComposerView()
        }
    }

    // MARK: - Phone Input

    private var phoneInputSection: some View {
        VStack(spacing: 20) {
            Text("Find your friends")
                .font(.system(size: 28, weight: .thin, design: .serif))
                .foregroundColor(.black)

            Text("Enter your phone number so friends can find you. We will never text you.")
                .font(.system(size: 15, weight: .regular, design: .serif))
                .foregroundColor(.black.opacity(0.5))
                .multilineTextAlignment(.center)

            TextField("Phone number", text: $phoneNumber)
                .keyboardType(.phonePad)
                .font(.system(size: 18, design: .monospaced))
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)

            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 13, design: .serif))
                    .foregroundColor(.red.opacity(0.7))
            }

            Button(action: { Task { await findFriends() } }) {
                Text(isLoading ? "Searching..." : "Find Friends")
                    .font(.system(size: 18, weight: .medium, design: .serif))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.black)
                    .cornerRadius(26)
            }
            .disabled(phoneNumber.isEmpty || isLoading)
            .opacity(phoneNumber.isEmpty ? 0.5 : 1)
        }
    }

    // MARK: - Loading

    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Text("Looking for friends...")
                .font(.system(size: 15, weight: .regular, design: .serif))
                .foregroundColor(.black.opacity(0.5))
        }
        .padding(.top, 60)
    }

    // MARK: - Results

    private var resultsSection: some View {
        VStack(spacing: 24) {
            if !matchedFriends.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(matchedFriends.count) friend\(matchedFriends.count == 1 ? "" : "s") joined")
                        .font(.system(size: 22, weight: .thin, design: .serif))
                        .foregroundColor(.black)

                    ForEach(matchedFriends) { friend in
                        HStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.black.opacity(0.3))
                            Text(friend.name)
                                .font(.system(size: 16, weight: .regular, design: .serif))
                                .foregroundColor(.black.opacity(0.7))
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green.opacity(0.6))
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.6))
                .cornerRadius(16)
            } else {
                VStack(spacing: 8) {
                    Text("No friends found yet")
                        .font(.system(size: 20, weight: .thin, design: .serif))
                        .foregroundColor(.black)
                    Text("Be the first to invite them!")
                        .font(.system(size: 15, weight: .regular, design: .serif))
                        .foregroundColor(.black.opacity(0.5))
                }
                .padding(.top, 20)
            }

            Button(action: { inviteContacts() }) {
                HStack(spacing: 8) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14))
                    Text(matchedFriends.isEmpty ? "Invite Friends" : "Invite More Friends")
                        .font(.system(size: 16, weight: .medium, design: .serif))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.black)
                .cornerRadius(24)
            }

            Button(action: { resetAndResearch() }) {
                Text("Search again")
                    .font(.system(size: 14, weight: .regular, design: .serif))
                    .foregroundColor(.black.opacity(0.4))
            }
        }
    }

    // MARK: - Logic

    private func findFriends() async {
        guard !phoneNumber.isEmpty else { return }
        errorMessage = nil
        isLoading = true

        // Store phone number locally
        UserDefaults.standard.set(phoneNumber, forKey: "userPhoneNumber")

        // Hash and register our phone number
        guard let phoneHash = ContactsManager.hashPhoneNumber(phoneNumber) else {
            errorMessage = "Invalid phone number"
            isLoading = false
            return
        }

        await registerPhoneHash(phoneHash)

        // Request contacts access
        let granted = await ContactsManager.requestAccess()
        guard granted else {
            errorMessage = "Contacts access is needed to find friends. You can enable it in Settings."
            isLoading = false
            return
        }

        // Fetch and hash contacts
        let contacts = await ContactsManager.fetchContactPhoneHashes()
        guard !contacts.isEmpty else {
            isLoading = false
            hasSearched = true
            UserDefaults.standard.set(true, forKey: "hasSearchedFriends")
            return
        }

        // Match against backend
        let hashes = contacts.map { $0.hash }
        let matchedHashes = await matchContacts(hashes: hashes)
        let matchedSet = Set(matchedHashes)

        matchedFriends = contacts.filter { matchedSet.contains($0.hash) }

        // Cache results
        cacheResults()
        hasSearched = true
        isLoading = false
        UserDefaults.standard.set(true, forKey: "hasSearchedFriends")
        UserDefaults.standard.set(matchedFriends.count, forKey: "friendMatchCount")
    }

    private func registerPhoneHash(_ hash: String) async {
        guard let url = URL(string: "\(Self.apiBase)/join") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let deviceId = DeviceID.getOrCreate()
        let body: [String: String] = ["device_id": deviceId, "phone_hash": hash]
        request.httpBody = try? JSONEncoder().encode(body)
        do {
            _ = try await URLSession.shared.data(for: request)
        } catch {
            os_log("Failed to register phone hash: %{public}@", type: .error, error.localizedDescription)
        }
    }

    private func matchContacts(hashes: [String]) async -> [String] {
        guard let url = URL(string: "\(Self.apiBase)/match") else { return [] }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["device_id": DeviceID.getOrCreate(), "contact_hashes": hashes]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let matched = json["matched_hashes"] as? [String] {
                return matched
            }
        } catch {
            os_log("Failed to match contacts: %{public}@", type: .error, error.localizedDescription)
        }
        return []
    }

    private func cacheResults() {
        if let data = try? JSONEncoder().encode(matchedFriends) {
            UserDefaults.standard.set(data, forKey: "cachedMatchedFriends")
        }
    }

    private func loadCachedResults() {
        guard hasSearched else { return }
        if let data = UserDefaults.standard.data(forKey: "cachedMatchedFriends"),
           let cached = try? JSONDecoder().decode([ContactMatch].self, from: data) {
            matchedFriends = cached
        }
    }

    private func inviteContacts() {
        guard MFMessageComposeViewController.canSendText() else { return }
        showMessageComposer = true
    }

    private func resetAndResearch() {
        hasSearched = false
        matchedFriends = []
        UserDefaults.standard.set(false, forKey: "hasSearchedFriends")
        UserDefaults.standard.removeObject(forKey: "cachedMatchedFriends")
        UserDefaults.standard.set(0, forKey: "friendMatchCount")
    }
}

// MARK: - Message Composer

struct MessageComposerView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let vc = MFMessageComposeViewController()
        vc.body = "I'm committing to a day of digital sabbath on June 21, 2026. You can join me by downloading Digital Sabbath: https://digitalsabbath.live"
        vc.messageComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true)
        }
    }
}
