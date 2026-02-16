import SwiftUI

struct OnboardingView: View {
    @ObservedObject var vpnManager: VPNManager
    @Binding var hasOnboarded: Bool

    @State private var step: OnboardingStep = .mission
    @State private var isLoading = false
    @State private var showBlockedApps = false

    enum OnboardingStep {
        case mission
        case permission
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            switch step {
            case .mission:
                missionView
                    .transition(.opacity)
            case .permission:
                permissionView
                    .transition(.opacity)
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
                step = .permission
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

    // MARK: - Step 2: Permission

    private var permissionView: some View {
        VStack(spacing: 0) {
            infoButton

            Spacer()

            Text("One small step")
                .font(.system(size: 36, weight: .thin, design: .serif))
                .foregroundColor(.black)
                .padding(.bottom, 32)

            Text("On the day of Digital Sabbath, the app will block scrolling apps by filtering their network requests on your device.")
                .font(.system(size: 17, weight: .regular, design: .serif))
                .foregroundColor(.black.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 16)

            Text("Your data never leaves your device.")
                .font(.system(size: 15, weight: .regular, design: .serif))
                .foregroundColor(.black.opacity(0.4))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)

            Spacer()

            Button(action: {
                isLoading = true
                vpnManager.installAndEnable { success in
                    isLoading = false
                    if success {
                        Task { await Self.registerJoin() }
                        hasOnboarded = true
                    }
                }
            }) {
                Group {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Unlock Digital Sabbath")
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
