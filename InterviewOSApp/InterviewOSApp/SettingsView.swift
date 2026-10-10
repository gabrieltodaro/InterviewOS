import SwiftUI
import InterviewOSApplePersistence

struct SettingsView: View {
    let syncEnabled: Bool
    let actualSyncMode: SyncMode
    let onSyncToggle: (Bool) -> Void

    @State private var toggleValue: Bool

    init(syncEnabled: Bool, actualSyncMode: SyncMode, onSyncToggle: @escaping (Bool) -> Void) {
        self.syncEnabled = syncEnabled
        self.actualSyncMode = actualSyncMode
        self.onSyncToggle = onSyncToggle
        _toggleValue = State(initialValue: syncEnabled)
    }

    var body: some View {
        Form {
            Section("Sync") {
                Toggle("iCloud Sync", isOn: Binding(
                    get: { toggleValue },
                    set: { newValue in
                        toggleValue = newValue
                        onSyncToggle(newValue)
                    }
                ))

                Text("Offline-first mode is always enabled. Turning on iCloud sync requires iCloud + CloudKit capability in the Xcode target.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                HStack {
                    Text("Current Mode")
                    Spacer()
                    Text(actualSyncMode == .cloudKit ? "CloudKit" : "Local Only")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Permissions") {
                Text("Calendar and notification permissions are requested the first time you schedule an interview action from a card.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .onChange(of: syncEnabled) { _, newValue in
            toggleValue = newValue
        }
    }
}
