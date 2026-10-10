import Foundation
import SwiftUI
import InterviewOSDomain
import InterviewOSPersistence

private struct AppServicesKey: EnvironmentKey {
    static let defaultValue: any AppServices = UnavailableAppServices()
}

private struct InterviewSchedulerKey: EnvironmentKey {
    static let defaultValue: any InterviewScheduler = UnavailableInterviewScheduler()
}

public extension EnvironmentValues {
    var appServices: any AppServices {
        get { self[AppServicesKey.self] }
        set { self[AppServicesKey.self] = newValue }
    }

    var interviewScheduler: any InterviewScheduler {
        get { self[InterviewSchedulerKey.self] }
        set { self[InterviewSchedulerKey.self] = newValue }
    }
}

public extension View {
    func appServices(_ services: any AppServices) -> some View {
        environment(\.appServices, services)
    }

    func interviewScheduler(_ scheduler: any InterviewScheduler) -> some View {
        environment(\.interviewScheduler, scheduler)
    }
}

public protocol InterviewScheduler: AnyObject {
    @MainActor
    func upsertCalendarEvent(
        for card: ProcessCard,
        opportunity: Opportunity,
        company: Company
    ) async throws -> String

    @MainActor
    func scheduleNotification(
        for card: ProcessCard,
        opportunity: Opportunity,
        company: Company
    ) async throws -> String
}

private enum UIErrors {
    static func missingServicesMessage() -> String {
        "AppServices was not injected into the environment."
    }

    static func missingSchedulerMessage() -> String {
        "InterviewScheduler was not injected into the environment."
    }
}

private struct UnavailableRepositoryError: LocalizedError {
    let message: String

    var errorDescription: String? {
        message
    }
}

private final class UnavailableOpportunityRepository: OpportunityRepository {
    func list(search _: String?) throws -> [Opportunity] { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
    func fetch(id _: UUID) throws -> Opportunity? { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
    func create(_ : Opportunity) throws { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
    func update(_ : Opportunity) throws { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
    func delete(id _: UUID) throws { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }

    func listCompanies(search _: String?) throws -> [Company] { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
    func fetchCompany(id _: UUID) throws -> Company? { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
    func createCompany(_ : Company) throws { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
    func upsertCompany(named _: String, websiteURL _: URL?) throws -> Company { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
}

private final class UnavailableStageRepository: StageRepository {
    func list(opportunityId _: UUID) throws -> [Stage] { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
    func fetch(id _: UUID) throws -> Stage? { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
    func create(_ : Stage) throws { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
    func update(_ : Stage) throws { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
    func delete(id _: UUID) throws { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
    func reorder(opportunityId _: UUID, orderedStageIds _: [UUID]) throws { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
}

private final class UnavailableCardRepository: CardRepository {
    func list(opportunityId _: UUID) throws -> [ProcessCard] { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
    func list(stageId _: UUID) throws -> [ProcessCard] { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
    func fetch(id _: UUID) throws -> ProcessCard? { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
    func create(_ : ProcessCard) throws { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
    func update(_ : ProcessCard) throws { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
    func delete(id _: UUID) throws { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
    func move(cardId _: UUID, to _: UUID) throws { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
    func search(query _: String, opportunityId _: UUID?) throws -> [ProcessCard] { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
}

private final class UnavailableQuestionRepository: QuestionRepository {
    func list(search _: String?, tagNames _: [String]) throws -> [Question] { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
    func fetch(id _: UUID) throws -> Question? { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
    func create(_ : Question) throws { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
    func update(_ : Question) throws { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
    func delete(id _: UUID) throws { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
    func search(query _: String) throws -> [Question] { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
    func allTags() throws -> [Tag] { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
    func searchTags(query _: String) throws -> [Tag] { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
    func upsertTag(named _: String) throws -> Tag { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
}

private final class UnavailablePersonRepository: PersonRepository {
    func list(search _: String?) throws -> [Person] { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
    func fetch(id _: UUID) throws -> Person? { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
    func create(_ : Person) throws { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
    func update(_ : Person) throws { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
    func delete(id _: UUID) throws { throw UnavailableRepositoryError(message: UIErrors.missingServicesMessage()) }
}

private final class UnavailableAppServices: AppServices {
    let opportunities: OpportunityRepository = UnavailableOpportunityRepository()
    let stages: StageRepository = UnavailableStageRepository()
    let cards: CardRepository = UnavailableCardRepository()
    let questions: QuestionRepository = UnavailableQuestionRepository()
    let people: PersonRepository = UnavailablePersonRepository()
}

private final class UnavailableInterviewScheduler: InterviewScheduler {
    @MainActor
    func upsertCalendarEvent(for _: ProcessCard, opportunity _: Opportunity, company _: Company) async throws -> String {
        throw UnavailableRepositoryError(message: UIErrors.missingSchedulerMessage())
    }

    @MainActor
    func scheduleNotification(for _: ProcessCard, opportunity _: Opportunity, company _: Company) async throws -> String {
        throw UnavailableRepositoryError(message: UIErrors.missingSchedulerMessage())
    }
}
