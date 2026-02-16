import SwiftUI

struct BlockedAppsSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Social Media")) {
                    blockedAppRow("Instagram", domain: "instagram.com")
                    blockedAppRow("TikTok", domain: "tiktok.com")
                    blockedAppRow("Twitter / X", domain: "x.com")
                    blockedAppRow("Facebook", domain: "facebook.com")
                    blockedAppRow("Reddit", domain: "reddit.com")
                    blockedAppRow("Snapchat", domain: "snapchat.com")
                    blockedAppRow("Threads", domain: "threads.net")
                    blockedAppRow("Bluesky", domain: "bsky.app")
                }
                Section(header: Text("Gambling")) {
                    blockedAppRow("Kalshi", domain: "kalshi.com")
                    blockedAppRow("Polymarket", domain: "polymarket.com")
                }
                Section(header: Text("AI")) {
                    blockedAppRow("ChatGPT", domain: "chatgpt.com")
                    blockedAppRow("Gemini", domain: "gemini.google.com")
                    blockedAppRow("Claude", domain: "claude.ai")
                }
                Section(footer: Text("Apps will still open, but feeds and content won't load.")) {
                    EmptyView()
                }
            }
            .navigationTitle("Blocked Apps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func blockedAppRow(_ name: String, domain: String) -> some View {
        HStack {
            Text(name)
                .font(.system(size: 16))
            Spacer()
            Text(domain)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.secondary)
        }
    }
}
