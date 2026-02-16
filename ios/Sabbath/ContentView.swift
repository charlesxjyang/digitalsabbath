import SwiftUI

struct ContentView: View {
    @ObservedObject var screenTimeManager: ScreenTimeManager
    @State private var now = Date()
    @State private var showBlockedApps = false
    @State private var joinedCount: Int = max(1, UserDefaults.standard.integer(forKey: "joinedCount"))

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private static let apiBase = "https://digital-sabbath-api.charlesxjyang.workers.dev"

    private let discordURL = URL(string: "https://discord.gg/YOUR_INVITE_CODE")!

    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.94, blue: 0.90)
                .ignoresSafeArea()

            if SabbathSchedule.isSabbathActive() {
                sabbathActiveView
            } else {
                countdownView
            }
        }
        .onReceive(timer) { _ in
            now = Date()
        }
        .sheet(isPresented: $showBlockedApps) {
            BlockedAppsSheet()
        }
        .task {
            await fetchCount()
        }
    }

    private func fetchCount() async {
        guard let url = URL(string: "\(Self.apiBase)/count") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try? JSONDecoder().decode([String: Int].self, from: data),
               let count = json["count"] {
                joinedCount = max(1, count)
                UserDefaults.standard.set(count, forKey: "joinedCount")
            }
        } catch {}
    }

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

    private var countdownView: some View {
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

            Button(action: {
                UIApplication.shared.open(discordURL)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "bubble.left.fill")
                        .font(.system(size: 12))
                    Text("Join our Discord")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(Color(red: 0.34, green: 0.40, blue: 0.95))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(red: 0.34, green: 0.40, blue: 0.95).opacity(0.12))
                .cornerRadius(16)
            }
            .padding(.bottom, 60)
        }
    }

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
