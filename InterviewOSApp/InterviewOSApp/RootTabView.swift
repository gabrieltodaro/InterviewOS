import SwiftUI
import InterviewOSApplePersistence
import InterviewOSUI

struct RootTabView: View {
    let syncEnabled: Bool
    let actualSyncMode: SyncMode
    let onSyncToggle: (Bool) -> Void

    var body: some View {
        TabView {
            NavigationStack {
                OpportunitiesListView()
            }
            .tabItem {
                Label("Opportunities", systemImage: "briefcase")
            }

            NavigationStack {
                QuestionBankView()
            }
            .tabItem {
                Label("Question Bank", systemImage: "text.book.closed")
            }

            NavigationStack {
                SettingsView(
                    syncEnabled: syncEnabled,
                    actualSyncMode: actualSyncMode,
                    onSyncToggle: onSyncToggle
                )
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }
}
