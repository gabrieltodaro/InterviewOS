#if DEBUG
import Foundation
import InterviewOSDomain
import InterviewOSPersistence
private final class MockStore {
    var companies: [UUID: Company] = [:]
    var opportunities: [UUID: Opportunity] = [:]
    var stages: [UUID: Stage] = [:]
    var cards: [UUID: ProcessCard] = [:]
    var questions: [UUID: Question] = [:]
    var tags: [UUID: Tag] = [:]
    var people: [UUID: Person] = [:]
    init(seed: Bool = true) {
        guard seed else { return }
        let company = Company(name: "Acme Corp", websiteURL: URL(string: "https://acme.example"))
        companies[company.id] = company
        let opportunity = Opportunity(
            companyId: company.id,
            roleTitle: "Senior iOS Engineer",
            location: "New York",
            workMode: .hybrid,
            salaryRange: "$180k - $220k",
            benefitsNotes: "Great health benefits",
            jobDescription: "Build and scale a modular SwiftUI app.",
            notes: "Strong system design emphasis."
        )
        opportunities[opportunity.id] = opportunity
        let stages = DomainTemplates.defaultStages(for: opportunity.id)
        for stage in stages {
            self.stages[stage.id] = stage
        }
        if let schedulingStage = stages.first(where: { $0.title == "Scheduling" }) {
            let card = ProcessCard(
                opportunityId: opportunity.id,
                stageId: schedulingStage.id,
                title: "Recruiter Screen",
                kind: .hr,
                status: .scheduled,
                scheduledAt: Date().addingTimeInterval(60 * 60 * 24),
                durationMinutes: 30,
                people: [PersonRef(name: "Alex Recruiter")]
            )
            cards[card.id] = card
        }
        let swiftTag = Tag(name: "Swift")
        tags[swiftTag.id] = swiftTag
        let question = Question(
            text: "Explain value vs reference types in Swift.",
            tags: [swiftTag],
            difficulty: 2,
            notes: "Common screen question"
        )
        questions[question.id] = question
    }
}
private final class MockOpportunityRepository: OpportunityRepository {
    private let store: MockStore
    init(store: MockStore) {
        self.store = store
    }
    func list(search query: String?) throws -> [Opportunity] {
        let all = store.opportunities.values.sorted { $0.updatedAt > $1.updatedAt }
        let needle = query?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        guard !needle.isEmpty else { return all }
        return all.filter { opportunity in
            let roleMatch = opportunity.roleTitle.lowercased().contains(needle)
            let companyMatch = store.companies[opportunity.companyId]?.name.lowercased().contains(needle) ?? false
            return roleMatch || companyMatch
        }
    }
    func fetch(id: UUID) throws -> Opportunity? {
        store.opportunities[id]
    }
    func create(_ opportunity: Opportunity) throws {
        store.opportunities[opportunity.id] = opportunity
    }
    func update(_ opportunity: Opportunity) throws {
        guard store.opportunities[opportunity.id] != nil else {
            throw RepositoryError.notFound
        }
        store.opportunities[opportunity.id] = opportunity
    }
    func delete(id: UUID) throws {
        guard store.opportunities[id] != nil else {
            throw RepositoryError.notFound
        }
        store.opportunities.removeValue(forKey: id)
        store.stages = store.stages.filter { $0.value.opportunityId != id }
        store.cards = store.cards.filter { $0.value.opportunityId != id }
    }
    func listCompanies(search query: String?) throws -> [Company] {
        let all = store.companies.values.sorted { $0.name < $1.name }
        let needle = query?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        guard !needle.isEmpty else { return all }
        return all.filter { $0.name.lowercased().contains(needle) }
    }
    func fetchCompany(id: UUID) throws -> Company? {
        store.companies[id]
    }
    func createCompany(_ company: Company) throws {
        store.companies[company.id] = company
    }
    func upsertCompany(named name: String, websiteURL: URL?) throws -> Company {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw RepositoryError.validation("Company name is required")
        }
        if let existing = store.companies.values.first(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return existing
        }
        let company = Company(name: trimmed, websiteURL: websiteURL)
        store.companies[company.id] = company
        return company
    }
}
private final class MockStageRepository: StageRepository {
    private let store: MockStore
    init(store: MockStore) {
        self.store = store
    }
    func list(opportunityId: UUID) throws -> [Stage] {
        store.stages.values
            .filter { $0.opportunityId == opportunityId }
            .sorted { $0.order < $1.order }
    }
    func fetch(id: UUID) throws -> Stage? {
        store.stages[id]
    }
    func create(_ stage: Stage) throws {
        store.stages[stage.id] = stage
    }
    func update(_ stage: Stage) throws {
        guard store.stages[stage.id] != nil else {
            throw RepositoryError.notFound
        }
        store.stages[stage.id] = stage
    }
    func delete(id: UUID) throws {
        guard store.stages[id] != nil else {
            throw RepositoryError.notFound
        }
        store.stages.removeValue(forKey: id)
        store.cards = store.cards.filter { $0.value.stageId != id }
    }
    func reorder(opportunityId: UUID, orderedStageIds: [UUID]) throws {
        var index = 0
        for stageID in orderedStageIds {
            guard var stage = store.stages[stageID], stage.opportunityId == opportunityId else {
                continue
            }
            stage.order = index
            index += 1
            store.stages[stageID] = stage
        }
    }
}
private final class MockCardRepository: CardRepository {
    private let store: MockStore
    init(store: MockStore) {
        self.store = store
    }
    func list(opportunityId: UUID) throws -> [ProcessCard] {
        store.cards.values
            .filter { $0.opportunityId == opportunityId }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
    func list(stageId: UUID) throws -> [ProcessCard] {
        store.cards.values
            .filter { $0.stageId == stageId }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
    func fetch(id: UUID) throws -> ProcessCard? {
        store.cards[id]
    }
    func create(_ card: ProcessCard) throws {
        store.cards[card.id] = card
    }
    func update(_ card: ProcessCard) throws {
        guard store.cards[card.id] != nil else {
            throw RepositoryError.notFound
        }
        store.cards[card.id] = card
    }
    func delete(id: UUID) throws {
        guard store.cards[id] != nil else {
            throw RepositoryError.notFound
        }
        store.cards.removeValue(forKey: id)
    }
    func move(cardId: UUID, to stageId: UUID) throws {
        guard var card = store.cards[cardId] else {
            throw RepositoryError.notFound
        }
        card.stageId = stageId
        card.updatedAt = Date()
        store.cards[card.id] = card
    }
    func search(query: String, opportunityId: UUID?) throws -> [ProcessCard] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filtered = store.cards.values.filter { card in
            if let opportunityId, card.opportunityId != opportunityId {
                return false
            }
            return needle.isEmpty || card.title.lowercased().contains(needle)
        }
        return filtered.sorted { $0.updatedAt > $1.updatedAt }
    }
}
private final class MockQuestionRepository: QuestionRepository {
    private let store: MockStore
    init(store: MockStore) {
        self.store = store
    }
    func list(search query: String?, tagNames: [String]) throws -> [Question] {
        let needle = query?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        let requiredTags = Set(tagNames.map { $0.lowercased() })
        return store.questions.values
            .filter { question in
                let textMatches = needle.isEmpty || question.text.lowercased().contains(needle)
                guard textMatches else { return false }
                if requiredTags.isEmpty { return true }
                let questionTags = Set(question.tags.map { $0.name.lowercased() })
                return requiredTags.isSubset(of: questionTags)
            }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
    func fetch(id: UUID) throws -> Question? {
        store.questions[id]
    }
    func create(_ question: Question) throws {
        store.questions[question.id] = question
        for tag in question.tags {
            store.tags[tag.id] = tag
        }
    }
    func update(_ question: Question) throws {
        guard store.questions[question.id] != nil else {
            throw RepositoryError.notFound
        }
        store.questions[question.id] = question
        for tag in question.tags {
            store.tags[tag.id] = tag
        }
    }
    func delete(id: UUID) throws {
        guard store.questions[id] != nil else {
            throw RepositoryError.notFound
        }
        store.questions.removeValue(forKey: id)
    }
    func search(query: String) throws -> [Question] {
        try list(search: query, tagNames: [])
    }
    func allTags() throws -> [Tag] {
        store.tags.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func searchTags(query: String) throws -> [Tag] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let tags = try allTags()
        guard !needle.isEmpty else { return tags }
        return tags.filter { $0.name.lowercased().contains(needle) }
    }
    func upsertTag(named name: String) throws -> Tag {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw RepositoryError.validation("Tag name is required")
        }
        if let existing = store.tags.values.first(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return existing
        }
        let tag = Tag(name: trimmed)
        store.tags[tag.id] = tag
        return tag
    }
}
private final class MockPersonRepository: PersonRepository {
    private let store: MockStore
    init(store: MockStore) {
        self.store = store
    }
    func list(search query: String?) throws -> [Person] {
        let needle = query?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        let all = store.people.values.sorted { $0.name < $1.name }
        guard !needle.isEmpty else { return all }
        return all.filter { $0.name.lowercased().contains(needle) }
    }
    func fetch(id: UUID) throws -> Person? {
        store.people[id]
    }
    func create(_ person: Person) throws {
        store.people[person.id] = person
    }
    func update(_ person: Person) throws {
        guard store.people[person.id] != nil else {
            throw RepositoryError.notFound
        }
        store.people[person.id] = person
    }
    func delete(id: UUID) throws {
        guard store.people[id] != nil else {
            throw RepositoryError.notFound
        }
        store.people.removeValue(forKey: id)
    }
}
public final class MockAppServices: AppServices {
    public let opportunities: OpportunityRepository
    public let stages: StageRepository
    public let cards: CardRepository
    public let questions: QuestionRepository
    public let people: PersonRepository
    public static let preview: MockAppServices = MockAppServices(seed: true)
    public init(seed: Bool = false) {
        let store = MockStore(seed: seed)
        opportunities = MockOpportunityRepository(store: store)
        stages = MockStageRepository(store: store)
        cards = MockCardRepository(store: store)
        questions = MockQuestionRepository(store: store)
        people = MockPersonRepository(store: store)
    }
}
public final class MockInterviewScheduler: InterviewScheduler {
    public init() {}
    public func upsertCalendarEvent(
        for card: ProcessCard,
        opportunity _: Opportunity,
        company _: Company
    ) async throws -> String {
        card.calendarEventIdentifier ?? "mock-calendar-\(card.id.uuidString)"
    }
    public func scheduleNotification(
        for card: ProcessCard,
        opportunity _: Opportunity,
        company _: Company
    ) async throws -> String {
        card.notificationRequestIdentifier ?? "mock-notification-\(card.id.uuidString)"
    }
}
#endif
