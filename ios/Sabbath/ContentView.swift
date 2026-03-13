import SwiftUI
import os.log

struct ContentView: View {
    @ObservedObject var screenTimeManager: ScreenTimeManager
    @State private var now = Date()
    @State private var showBlockedApps = false
    @State private var joinedCount: Int = max(1, UserDefaults.standard.integer(forKey: "joinedCount"))

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private static let apiBase = "https://digital-sabbath-api.charlesxjyang.workers.dev"

    @State private var discordURL: String = ""
    @State private var shareURL: String = "https://digitalsabbath.live"
    @State private var showFriendsView = false
    @State private var showAppPicker = false
    @State private var showPreviewConfirm = false
    @State private var showAbout = false
    @State private var previewEndTime: Date? = {
        let ts = UserDefaults.standard.double(forKey: "previewEndTime")
        guard ts > 0 else { return nil }
        let date = Date(timeIntervalSince1970: ts)
        return date > Date() ? date : nil
    }()

    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.94, blue: 0.90)
                .ignoresSafeArea()

            if SabbathSchedule.isSabbathActive() {
                sabbathActiveView
            } else if screenTimeManager.isPreviewActive, let endTime = previewEndTime {
                previewActiveView(endTime: endTime)
            } else {
                countdownView
            }
        }
        .onReceive(timer) { _ in
            now = Date()
            if let endTime = previewEndTime, Date() >= endTime {
                screenTimeManager.stopPreview()
                previewEndTime = nil
                UserDefaults.standard.removeObject(forKey: "previewEndTime")
            }
        }
        .sheet(isPresented: $showBlockedApps) {
            BlockedAppsSheet(screenTimeManager: screenTimeManager)
        }
        .sheet(isPresented: $showFriendsView) {
            FriendsView()
        }
        .sheet(isPresented: $showAppPicker) {
            AppSelectionView(screenTimeManager: screenTimeManager)
        }
        .sheet(isPresented: $showAbout) {
            AboutSheet()
        }
        .alert("Start preview?", isPresented: $showPreviewConfirm) {
            Button("Start") { beginPreview() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your selected apps will be blocked for 1 hour.")
        }
        .task {
            await fetchCount()
            await fetchConfig()

            // Prompt app selection if sabbath is upcoming and no selection
            if SabbathSchedule.isUpcoming() && !screenTimeManager.hasSelection {
                showAppPicker = true
            }

            // Sabbath day: auto-start or prompt
            if SabbathSchedule.isSabbathActive() {
                if screenTimeManager.hasSelection && !screenTimeManager.isBlocking {
                    screenTimeManager.startBlocking()
                } else if !screenTimeManager.hasSelection {
                    showAppPicker = true
                }
            }
        }
    }

    // MARK: - Preview

    private func beginPreview() {
        screenTimeManager.startPreview()
        let endTime = Date().addingTimeInterval(3600)
        previewEndTime = endTime
        UserDefaults.standard.set(endTime.timeIntervalSince1970, forKey: "previewEndTime")
    }

    private func previewActiveView(endTime: Date) -> some View {
        VStack(spacing: 0) {
            Spacer()

            Text("Preview active")
                .font(.system(size: 32, weight: .thin, design: .serif))
                .foregroundColor(.black)
                .padding(.bottom, 16)

            let remaining = Calendar.current.dateComponents(
                [.minute, .second],
                from: now,
                to: endTime
            )
            let mins = max(0, remaining.minute ?? 0)
            let secs = max(0, remaining.second ?? 0)

            Text(String(format: "%02d:%02d", mins, secs))
                .font(.system(size: 44, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
                .padding(.bottom, 12)

            Text("remaining")
                .font(.system(size: 17, weight: .regular, design: .serif))
                .foregroundColor(.black.opacity(0.4))
                .padding(.bottom, 24)

            Text("Enjoy a mini digital sabbath.")
                .font(.system(size: 17, weight: .regular, design: .serif))
                .foregroundColor(.black.opacity(0.5))

            Spacer()
        }
    }

    // MARK: - Network

    private func fetchCount() async {
        guard let url = URL(string: "\(Self.apiBase)/count") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try? JSONDecoder().decode([String: Int].self, from: data),
               let count = json["count"] {
                joinedCount = max(1, count)
                UserDefaults.standard.set(count, forKey: "joinedCount")
            }
        } catch {
            os_log("Failed to fetch count: %{public}@", type: .error, error.localizedDescription)
        }
    }

    private func fetchConfig() async {
        guard let url = URL(string: "\(Self.apiBase)/config") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try? JSONDecoder().decode([String: String].self, from: data) {
                if let discord = json["discord_url"], !discord.isEmpty { discordURL = discord }
                if let share = json["share_url"], !share.isEmpty { shareURL = share }
            }
        } catch {
            os_log("Failed to fetch config: %{public}@", type: .error, error.localizedDescription)
        }
    }

    // MARK: - Sabbath Active

    private var sabbathEndOfDay: Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
        return tomorrow
    }

    private var sabbathActiveView: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: { showBlockedApps = true }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 22))
                        .foregroundColor(.black.opacity(0.4))
                }
                .padding(.trailing, 24)
                .padding(.top, 16)
            }

            Spacer()

            Text("Sabbath is active.")
                .font(.system(size: 32, weight: .thin, design: .serif))
                .foregroundColor(.black)
                .padding(.bottom, 16)

            let remaining = Calendar.current.dateComponents(
                [.hour, .minute, .second],
                from: now,
                to: sabbathEndOfDay
            )

            Text(sabbathRemainingString(from: remaining))
                .font(.system(size: 44, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
                .padding(.bottom, 12)

            Text("remaining")
                .font(.system(size: 17, weight: .regular, design: .serif))
                .foregroundColor(.black.opacity(0.4))
                .padding(.bottom, 24)

            Text("Be present.")
                .font(.system(size: 20, weight: .regular, design: .serif))
                .foregroundColor(.black.opacity(0.5))

            Spacer()
        }
    }

    // MARK: - Countdown

    private var countdownView: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: { showAbout = true }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 22))
                        .foregroundColor(.black.opacity(0.4))
                }
                .padding(.trailing, 24)
                .padding(.top, 16)
            }

            Spacer()

            Image("BackgroundImage")
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 32))
                .padding(.bottom, 32)

            if let next = SabbathSchedule.nextSabbathDate() {
                let components = Calendar.current.dateComponents(
                    [.day, .hour, .minute, .second],
                    from: now,
                    to: next
                )

                Text(countdownString(from: components))
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)

                Text("Digital Sabbath")
                    .font(.system(size: 20, weight: .regular, design: .serif))
                    .foregroundColor(.black.opacity(0.5))
                    .padding(.bottom, 4)

                Text("June 21, 2026")
                    .font(.system(size: 15, weight: .light, design: .serif))
                    .foregroundColor(.black.opacity(0.35))
            } else {
                Text("No upcoming sabbath scheduled")
                    .font(.system(size: 17, weight: .regular, design: .serif))
                    .foregroundColor(.black.opacity(0.5))
            }

            Spacer()

            Text("Join \(joinedCount) \(joinedCount == 1 ? "person" : "people") worldwide on a day of Digital Sabbath")
                .font(.system(size: 15, weight: .regular, design: .serif))
                .foregroundColor(.black.opacity(0.45))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 16)

            VStack(spacing: 10) {
                ShareLink(item: "I'm committing to a day of digital sabbath on June 21, 2026. You can join me by downloading Digital Sabbath: \(shareURL)") {
                    Text("Share")
                        .font(.system(size: 13, weight: .medium, design: .serif))
                        .foregroundColor(.black.opacity(0.6))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.08))
                        .cornerRadius(16)
                }

                Button(action: {
                    showBlockedApps = true
                }) {
                    Text("Edit blocked apps")
                        .font(.system(size: 13, weight: .medium, design: .serif))
                        .foregroundColor(.black.opacity(0.6))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.08))
                        .cornerRadius(16)
                }

                Button(action: {
                    if screenTimeManager.isAuthorized && screenTimeManager.hasSelection {
                        showPreviewConfirm = true
                    } else {
                        showAppPicker = true
                    }
                }) {
                    Text("Preview for 1 hour")
                        .font(.system(size: 13, weight: .medium, design: .serif))
                        .foregroundColor(.black.opacity(0.6))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.08))
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
    }

    // MARK: - Helpers

    private func countdownString(from components: DateComponents) -> String {
        let d = max(0, components.day ?? 0)
        let h = max(0, components.hour ?? 0)
        let m = max(0, components.minute ?? 0)
        let s = max(0, components.second ?? 0)
        return String(format: "%dd %02dh %02dm %02ds", d, h, m, s)
    }

    private func sabbathRemainingString(from components: DateComponents) -> String {
        let h = max(0, components.hour ?? 0)
        let m = max(0, components.minute ?? 0)
        let s = max(0, components.second ?? 0)
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}
