import SwiftUI
import SwiftData
import InterviewOSApplePersistence
import InterviewOSUI

@main
struct InterviewOSApp: App {
    @StateObject private var bootstrap = AppBootstrap()

    var body: some Scene {
        WindowGroup {
            RootTabView(
                syncEnabled: bootstrap.syncEnabled,
                actualSyncMode: bootstrap.stack.syncMode,
                onSyncToggle: { enabled in
                    bootstrap.updateSync(enabled: enabled)
                }
            )
            .appServices(bootstrap.stack.services)
            .interviewScheduler(bootstrap.scheduler)
            .modelContainer(bootstrap.stack.container)
        }
    }
}

@MainActor
final class AppBootstrap: ObservableObject {
    @Published private(set) var stack: SwiftDataStack
    @Published private(set) var syncEnabled: Bool

    let scheduler = AppleInterviewScheduler()

    private let defaultsKey = "InterviewOS.iCloudSyncEnabled"

    init() {
        let storedSync = UserDefaults.standard.bool(forKey: defaultsKey)
        let desiredMode: SyncMode = storedSync ? .cloudKit : .localOnly
        let stack = SwiftDataStack(syncMode: desiredMode)

        self.stack = stack
        self.syncEnabled = stack.syncMode == .cloudKit
        UserDefaults.standard.set(self.syncEnabled, forKey: defaultsKey)
    }

    func updateSync(enabled: Bool) {
        let desiredMode: SyncMode = enabled ? .cloudKit : .localOnly
        let newStack = SwiftDataStack(syncMode: desiredMode)
        stack = newStack

        let effectiveEnabled = newStack.syncMode == .cloudKit
        syncEnabled = effectiveEnabled
        UserDefaults.standard.set(effectiveEnabled, forKey: defaultsKey)
    }
}
