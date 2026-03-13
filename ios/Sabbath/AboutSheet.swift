import SwiftUI

struct AboutSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                HStack(spacing: 0) {
                    Text("Made with care by ")
                        .font(.system(size: 17, weight: .regular, design: .serif))
                        .foregroundColor(.black.opacity(0.65))
                    Link("Charles Yang", destination: URL(string: "https://charlesyang.io/")!)
                        .font(.system(size: 17, weight: .regular, design: .serif))
                    Text(".")
                        .font(.system(size: 17, weight: .regular, design: .serif))
                        .foregroundColor(.black.opacity(0.65))
                }

                HStack(spacing: 0) {
                    Text("Fully open source on ")
                        .font(.system(size: 17, weight: .regular, design: .serif))
                        .foregroundColor(.black.opacity(0.65))
                    Link("GitHub", destination: URL(string: "https://github.com/charlesxjyang/digitalsabbath")!)
                        .font(.system(size: 17, weight: .regular, design: .serif))
                    Text(".")
                        .font(.system(size: 17, weight: .regular, design: .serif))
                        .foregroundColor(.black.opacity(0.65))
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
