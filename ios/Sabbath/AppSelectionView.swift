import SwiftUI
import FamilyControls

struct AppSelectionView: View {
    @ObservedObject var screenTimeManager: ScreenTimeManager
    var onComplete: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.black.opacity(0.4))
                }
                .padding(.trailing, 24)
                .padding(.top, 20)
            }

            Spacer()

            Image(systemName: "shield.checkered")
                .font(.system(size: 48))
                .foregroundColor(.black.opacity(0.3))
                .padding(.bottom, 24)

            Text("Choose apps to block")
                .font(.system(size: 32, weight: .thin, design: .serif))
                .foregroundColor(.black)
                .padding(.bottom, 24)

            Text("We recommend blocking any apps with scrolling or swiping feeds for your day of digital sabbath.")
                .font(.system(size: 17, weight: .regular, design: .serif))
                .foregroundColor(.black.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 16)

            Text("You can change this anytime.")
                .font(.system(size: 15, weight: .regular, design: .serif))
                .foregroundColor(.black.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            FamilyActivityPicker(selection: $screenTimeManager.activitySelection)
                .frame(height: 300)
                .padding(.horizontal, 16)

            Button(action: {
                screenTimeManager.saveSelection()
                onComplete?()
                dismiss()
            }) {
                Text("Done")
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
}
