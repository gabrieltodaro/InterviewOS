import Foundation
import InterviewOSDomain

public enum RepositoryError: Error, LocalizedError {
    case notFound
    case validation(String)

    public var errorDescription: String? {
        switch self {
        case .notFound:
            "Requested entity was not found."
        case let .validation(message):
            message
        }
    }
}

public protocol OpportunityRepository {
    func list(search query: String?) throws -> [Opportunity]
    func fetch(id: UUID) throws -> Opportunity?
    func create(_ opportunity: Opportunity) throws
    func update(_ opportunity: Opportunity) throws
    func delete(id: UUID) throws

    func listCompanies(search query: String?) throws -> [Company]
    func fetchCompany(id: UUID) throws -> Company?
    func createCompany(_ company: Company) throws
    func upsertCompany(named name: String, websiteURL: URL?) throws -> Company
}

public protocol StageRepository {
    func list(opportunityId: UUID) throws -> [Stage]
    func fetch(id: UUID) throws -> Stage?
    func create(_ stage: Stage) throws
    func update(_ stage: Stage) throws
    func delete(id: UUID) throws
    func reorder(opportunityId: UUID, orderedStageIds: [UUID]) throws
}

public protocol CardRepository {
    func list(opportunityId: UUID) throws -> [ProcessCard]
    func list(stageId: UUID) throws -> [ProcessCard]
    func fetch(id: UUID) throws -> ProcessCard?
    func create(_ card: ProcessCard) throws
    func update(_ card: ProcessCard) throws
    func delete(id: UUID) throws
    func move(cardId: UUID, to stageId: UUID) throws
    func search(query: String, opportunityId: UUID?) throws -> [ProcessCard]
}

public protocol QuestionRepository {
    func list(search query: String?, tagNames: [String]) throws -> [Question]
    func fetch(id: UUID) throws -> Question?
    func create(_ question: Question) throws
    func update(_ question: Question) throws
    func delete(id: UUID) throws
    func search(query: String) throws -> [Question]
    func allTags() throws -> [Tag]
    func searchTags(query: String) throws -> [Tag]
    func upsertTag(named name: String) throws -> Tag
}

public protocol PersonRepository {
    func list(search query: String?) throws -> [Person]
    func fetch(id: UUID) throws -> Person?
    func create(_ person: Person) throws
    func update(_ person: Person) throws
    func delete(id: UUID) throws
}

public protocol AppServices {
    var opportunities: OpportunityRepository { get }
    var stages: StageRepository { get }
    var cards: CardRepository { get }
    var questions: QuestionRepository { get }
    var people: PersonRepository { get }
}
