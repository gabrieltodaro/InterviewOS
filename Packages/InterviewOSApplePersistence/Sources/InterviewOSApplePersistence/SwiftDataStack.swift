import Foundation
import SwiftData

public enum SyncMode: String, Codable, Sendable {
    case localOnly
    case cloudKit
}

public enum ModelContainerFactory {
    public static func makeContainer(syncMode: SyncMode) throws -> ModelContainer {
        let schema = Schema([
            SDCompany.self,
            SDOpportunity.self,
            SDStage.self,
            SDCard.self,
            SDQuestion.self,
            SDTag.self,
            SDPerson.self
        ])

        let configuration: ModelConfiguration
        switch syncMode {
        case .localOnly:
            configuration = ModelConfiguration(
                "InterviewOS",
                schema: schema,
                cloudKitDatabase: .none
            )
        case .cloudKit:
            configuration = ModelConfiguration(
                "InterviewOS",
                schema: schema,
                cloudKitDatabase: .automatic
            )
        }

        return try ModelContainer(for: schema, configurations: [configuration])
    }

    public static func makeContainerWithFallback(syncMode: SyncMode) -> (container: ModelContainer, actualMode: SyncMode) {
        if syncMode == .cloudKit, let cloudKitContainer = try? makeContainer(syncMode: .cloudKit) {
            return (cloudKitContainer, .cloudKit)
        }

        let localContainer = try? makeContainer(syncMode: .localOnly)
        if let localContainer {
            return (localContainer, .localOnly)
        }

        fatalError("Unable to create SwiftData container in either CloudKit or local-only mode.")
    }
}

@MainActor
public final class SwiftDataStack {
    public let container: ModelContainer
    public let services: AppleAppServices
    public let syncMode: SyncMode

    public init(syncMode: SyncMode = .localOnly) {
        let resolved = ModelContainerFactory.makeContainerWithFallback(syncMode: syncMode)
        self.container = resolved.container
        self.services = AppleAppServices(context: resolved.container.mainContext)
        self.syncMode = resolved.actualMode
    }
}
