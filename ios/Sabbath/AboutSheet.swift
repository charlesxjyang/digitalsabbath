import SwiftUI

struct AboutSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                Text("Made with care by Charles Yang.")
                    .font(.system(size: 17, weight: .regular, design: .serif))
                    .foregroundColor(.black.opacity(0.65))
                    .multilineTextAlignment(.center)

                Text("Fully open source on GitHub.")
                    .font(.system(size: 17, weight: .regular, design: .serif))
                    .foregroundColor(.black.opacity(0.65))
                    .multilineTextAlignment(.center)

                Link(destination: URL(string: "https://github.com/charlesxjyang/digitalsabbath")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "link")
                            .font(.system(size: 13))
                        Text("github.com/charlesxjyang/digitalsabbath")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                    }
                    .foregroundColor(.blue.opacity(0.8))
                }

                Spacer()
            }
            .padding(.horizontal, 40)
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
