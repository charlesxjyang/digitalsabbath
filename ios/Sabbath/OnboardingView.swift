import SwiftUI
import FamilyControls

struct OnboardingView: View {
    @ObservedObject var screenTimeManager: ScreenTimeManager
    @Binding var hasOnboarded: Bool

    @State private var step: OnboardingStep = .mission
    @State private var isLoading = false
    @State private var showBlockedApps = false

    enum OnboardingStep {
        case mission
        case pickApps
        case done
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            switch step {
            case .mission:
                missionView
                    .transition(.opacity)
            case .pickApps:
                pickAppsView
                    .transition(.opacity)
            case .done:
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.4), value: step)
        .sheet(isPresented: $showBlockedApps) {
            BlockedAppsSheet()
        }
    }

    private var infoButton: some View {
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
    }

    // MARK: - Step 1: Mission

    private var missionView: some View {
        VStack(spacing: 0) {
            infoButton

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
                step = .pickApps
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

    // MARK: - Step 2: Pick Apps

    private var pickAppsView: some View {
        VStack(spacing: 0) {
            infoButton

            Spacer()

            Text("Choose what to block")
                .font(.system(size: 36, weight: .thin, design: .serif))
                .foregroundColor(.black)
                .padding(.bottom, 16)

            Text("Select the apps you want blocked on Digital Sabbath. You can change this anytime.")
                .font(.system(size: 17, weight: .regular, design: .serif))
                .foregroundColor(.black.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 32)

            FamilyActivityPicker(selection: $screenTimeManager.activitySelection)
                .frame(height: 300)
                .padding(.horizontal, 20)

            Spacer()

            Button(action: {
                isLoading = true
                Task {
                    await screenTimeManager.requestAuthorization()
                    screenTimeManager.saveSelection()
                    screenTimeManager.scheduleAllSabbaths()
                    await Self.registerJoin()
                    await MainActor.run {
                        isLoading = false
                        hasOnboarded = true
                    }
                }
            }) {
                Group {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Activate Digital Sabbath")
                            .font(.system(size: 18, weight: .medium, design: .serif))
                    }
                }
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

    private static func registerJoin() async {
        guard let url = URL(string: "https://digital-sabbath-api.charlesxjyang.workers.dev/join") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        _ = try? await URLSession.shared.data(for: request)
    }
}
