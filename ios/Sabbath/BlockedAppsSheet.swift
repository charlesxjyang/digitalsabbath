import SwiftUI
import FamilyControls

struct BlockedAppsSheet: View {
    @ObservedObject var screenTimeManager: ScreenTimeManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if screenTimeManager.hasSelection {
                    let appCount = screenTimeManager.activitySelection.applicationTokens.count
                    let catCount = screenTimeManager.activitySelection.categoryTokens.count

                    Text("\(appCount) app\(appCount == 1 ? "" : "s") and \(catCount) categor\(catCount == 1 ? "y" : "ies") selected")
                        .font(.system(size: 15, weight: .regular, design: .serif))
                        .foregroundColor(.black.opacity(0.5))
                        .padding(.top, 20)
                        .padding(.bottom, 8)
                } else {
                    Text("No apps selected yet")
                        .font(.system(size: 15, weight: .regular, design: .serif))
                        .foregroundColor(.black.opacity(0.5))
                        .padding(.top, 20)
                        .padding(.bottom, 8)
                }

                FamilyActivityPicker(selection: $screenTimeManager.activitySelection)
            }
            .navigationTitle("Blocked Apps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        screenTimeManager.saveSelection()
                        dismiss()
                    }
                }
            }
        }
    }
}
