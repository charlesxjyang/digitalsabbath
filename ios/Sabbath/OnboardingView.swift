import SwiftUI
import os.log

struct OnboardingView: View {
    @Binding var hasOnboarded: Bool
    @ObservedObject var screenTimeManager: ScreenTimeManager

    @State private var step: OnboardingStep = .mission
    @State private var showAbout = false
    @State private var showFriendsView = false
    @State private var showAppPicker = false

    enum OnboardingStep {
        case mission
        case selectApps
        case findFriends
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            switch step {
            case .mission:
                missionView
                    .transition(.opacity)
            case .selectApps:
                selectAppsView
                    .transition(.opacity)
            case .findFriends:
                findFriendsPromptView
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: step)
        .sheet(isPresented: $showAbout) {
            AboutSheet()
        }
    }

    private func navBar(showBack: Bool = false, backAction: (() -> Void)? = nil) -> some View {
        HStack {
            if showBack, let backAction = backAction {
                Button(action: backAction) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.black.opacity(0.4))
                }
                .padding(.leading, 24)
                .padding(.top, 16)
            }
            Spacer()
            Button(action: { showAbout = true }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 22))
                    .foregroundColor(.black.opacity(0.4))
            }
            .padding(.trailing, 24)
            .padding(.top, 16)
        }
    }

    // MARK: - Step 1: Mission

    private var missionView: some View {
        VStack(spacing: 0) {
            navBar()

            Spacer()

            Text("Digital Sabbath")
                .font(.system(size: 48, weight: .thin, design: .serif))
                .foregroundColor(.black)
                .padding(.bottom, 32)

            Text("On June 21, 2026, we all put down our phones together.")
                .font(.system(size: 19, weight: .regular, design: .serif))
                .foregroundColor(.black.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 16)

            Text("No doomscrolling. \n One Day of Collective Rest.")
                .font(.system(size: 16, weight: .regular, design: .serif))
                .foregroundColor(.black.opacity(0.4))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)

            Spacer()

            Button(action: {
                Task {
                    await Self.registerJoin()
                    await screenTimeManager.requestAuthorization()
                }
                step = .selectApps
            }) {
                Text("I'm in")
                    .font(.system(size: 18, weight: .medium, design: .serif))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.black)
                    .cornerRadius(28)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
    }

    // MARK: - Step 2: Select Apps

    private var selectAppsView: some View {
        VStack(spacing: 0) {
            navBar(showBack: true) { step = .mission }

            Spacer()

            Image(systemName: "shield.checkered")
                .font(.system(size: 48))
                .foregroundColor(.black.opacity(0.3))
                .padding(.bottom, 24)

            Text("Choose apps to block")
                .font(.system(size: 36, weight: .thin, design: .serif))
                .foregroundColor(.black)
                .padding(.bottom, 32)

            Text("Select the apps you want blocked during Digital Sabbath on June 21, 2026.")
                .font(.system(size: 17, weight: .regular, design: .serif))
                .foregroundColor(.black.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button(action: {
                showAppPicker = true
            }) {
                Text("Select Apps")
                    .font(.system(size: 18, weight: .medium, design: .serif))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.black)
                    .cornerRadius(28)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
        .sheet(isPresented: $showAppPicker) {
            AppSelectionView(screenTimeManager: screenTimeManager) {
                step = .findFriends
            }
        }
    }

    // MARK: - Step 3: Find Friends

    private var findFriendsPromptView: some View {
        VStack(spacing: 0) {
            navBar(showBack: true) { step = .selectApps }

            Spacer()

            Image(systemName: "person.2.fill")
                .font(.system(size: 48))
                .foregroundColor(.black.opacity(0.3))
                .padding(.bottom, 24)

            Text("Find your friends")
                .font(.system(size: 36, weight: .thin, design: .serif))
                .foregroundColor(.black)
                .padding(.bottom, 32)

            Text("See which of your contacts have joined Digital Sabbath and invite the rest.")
                .font(.system(size: 17, weight: .regular, design: .serif))
                .foregroundColor(.black.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 16)

            Spacer()

            Button(action: {
                showFriendsView = true
            }) {
                Text("Find Friends")
                    .font(.system(size: 18, weight: .medium, design: .serif))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.black)
                    .cornerRadius(28)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 12)

            Button(action: {
                hasOnboarded = true
            }) {
                Text("Maybe later")
                    .font(.system(size: 16, weight: .regular, design: .serif))
                    .foregroundColor(.black.opacity(0.4))
            }
            .padding(.bottom, 60)
        }
        .sheet(isPresented: $showFriendsView, onDismiss: {
            hasOnboarded = true
        }) {
            FriendsView()
        }
    }

    private static func registerJoin() async {
        guard let url = URL(string: "https://digital-sabbath-api.charlesxjyang.workers.dev/join") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let deviceId = DeviceID.getOrCreate()
        let body = ["device_id": deviceId]
        request.httpBody = try? JSONEncoder().encode(body)
        do {
            _ = try await URLSession.shared.data(for: request)
        } catch {
            os_log("Failed to register join: %{public}@", type: .error, error.localizedDescription)
        }
    }
}
