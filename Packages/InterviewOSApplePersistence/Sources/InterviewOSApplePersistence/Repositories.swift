import Foundation
import SwiftData
import InterviewOSDomain
import InterviewOSPersistence
public final class SwiftDataOpportunityRepository: OpportunityRepository {
    private let context: ModelContext
    public init(context: ModelContext) {
        self.context = context
    }
    public func list(search query: String?) throws -> [Opportunity] {
        let descriptor = FetchDescriptor<SDOpportunity>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        let all = try context.fetch(descriptor)
        let needle = query?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        if needle.isEmpty {
            return all.map { $0.toDomain() }
        }
        return all.compactMap { model in
            let companyName = (model.company?.name ?? "").lowercased()
            let role = model.roleTitle.lowercased()
            if role.contains(needle) || companyName.contains(needle) {
                return model.toDomain()
            }
            return nil
        }
    }
    public func fetch(id: UUID) throws -> Opportunity? {
        let descriptor = FetchDescriptor<SDOpportunity>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first?.toDomain()
    }
    public func create(_ opportunity: Opportunity) throws {
        guard let company = try fetchCompanyModel(id: opportunity.companyId) else {
            throw RepositoryError.validation("Cannot create opportunity: company does not exist.")
        }
        let model = SDOpportunity(
            id: opportunity.id,
            companyID: opportunity.companyId,
            roleTitle: opportunity.roleTitle,
            location: opportunity.location,
            workModeRawValue: opportunity.workMode.rawValue,
            salaryRange: opportunity.salaryRange,
            benefitsNotes: opportunity.benefitsNotes,
            jobDescription: opportunity.jobDescription,
            notes: opportunity.notes,
            createdAt: opportunity.createdAt,
            updatedAt: opportunity.updatedAt,
            company: company
        )
        context.insert(model)
        try context.save()
    }
    public func update(_ opportunity: Opportunity) throws {
        guard let model = try fetchOpportunityModel(id: opportunity.id) else {
            throw RepositoryError.notFound
        }
        guard let company = try fetchCompanyModel(id: opportunity.companyId) else {
            throw RepositoryError.validation("Cannot update opportunity: company does not exist.")
        }
        model.apply(opportunity)
        model.company = company
        model.companyID = company.id
        try context.save()
    }
    public func delete(id: UUID) throws {
        guard let model = try fetchOpportunityModel(id: id) else {
            throw RepositoryError.notFound
        }
        context.delete(model)
        try context.save()
    }
    public func listCompanies(search query: String?) throws -> [Company] {
        let descriptor = FetchDescriptor<SDCompany>(sortBy: [SortDescriptor(\.name)])
        let companies = try context.fetch(descriptor)
        let needle = query?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        if needle.isEmpty {
            return companies.map { $0.toDomain() }
        }
        return companies
            .filter { $0.name.lowercased().contains(needle) }
            .map { $0.toDomain() }
    }
    public func fetchCompany(id: UUID) throws -> Company? {
        try fetchCompanyModel(id: id)?.toDomain()
    }
    public func createCompany(_ company: Company) throws {
        if try fetchCompanyModel(id: company.id) != nil {
            throw RepositoryError.validation("A company with this identifier already exists.")
        }
        let model = SDCompany(
            id: company.id,
            name: company.name,
            websiteURLString: company.websiteURL?.absoluteString
        )
        context.insert(model)
        try context.save()
    }
    public func upsertCompany(named name: String, websiteURL: URL?) throws -> Company {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedName.isEmpty else {
            throw RepositoryError.validation("Company name is required.")
        }
        let descriptor = FetchDescriptor<SDCompany>(sortBy: [SortDescriptor(\.name)])
        let companies = try context.fetch(descriptor)
        if let existing = companies.first(where: { $0.name.caseInsensitiveCompare(normalizedName) == .orderedSame }) {
            if let websiteURL {
                existing.websiteURLString = websiteURL.absoluteString
                try context.save()
            }
            return existing.toDomain()
        }
        let newCompany = SDCompany(
            id: UUID(),
            name: normalizedName,
            websiteURLString: websiteURL?.absoluteString
        )
        context.insert(newCompany)
        try context.save()
        return newCompany.toDomain()
    }
    private func fetchCompanyModel(id: UUID) throws -> SDCompany? {
        let descriptor = FetchDescriptor<SDCompany>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first
    }
    private func fetchOpportunityModel(id: UUID) throws -> SDOpportunity? {
        let descriptor = FetchDescriptor<SDOpportunity>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first
    }
}
public final class SwiftDataStageRepository: StageRepository {
    private let context: ModelContext
    public init(context: ModelContext) {
        self.context = context
    }
    public func list(opportunityId: UUID) throws -> [Stage] {
        let descriptor = FetchDescriptor<SDStage>(
            predicate: #Predicate { $0.opportunityID == opportunityId },
            sortBy: [SortDescriptor(\.order)]
        )
        return try context.fetch(descriptor).map { $0.toDomain() }
    }
    public func fetch(id: UUID) throws -> Stage? {
        let descriptor = FetchDescriptor<SDStage>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first?.toDomain()
    }
    public func create(_ stage: Stage) throws {
        guard let opportunity = try fetchOpportunityModel(id: stage.opportunityId) else {
            throw RepositoryError.validation("Cannot create stage: opportunity not found.")
        }
        let model = SDStage(
            id: stage.id,
            opportunityID: stage.opportunityId,
            title: stage.title,
            order: stage.order,
            isClosedColumn: stage.isClosedColumn,
            opportunity: opportunity
        )
        context.insert(model)
        try context.save()
    }
    public func update(_ stage: Stage) throws {
        guard let model = try fetchStageModel(id: stage.id) else {
            throw RepositoryError.notFound
        }
        guard let opportunity = try fetchOpportunityModel(id: stage.opportunityId) else {
            throw RepositoryError.validation("Cannot update stage: opportunity not found.")
        }
        model.apply(stage)
        model.opportunity = opportunity
        try context.save()
    }
    public func delete(id: UUID) throws {
        guard let model = try fetchStageModel(id: id) else {
            throw RepositoryError.notFound
        }
        context.delete(model)
        try context.save()
    }
    public func reorder(opportunityId: UUID, orderedStageIds: [UUID]) throws {
        guard !orderedStageIds.isEmpty else { return }
        let descriptor = FetchDescriptor<SDStage>(
            predicate: #Predicate { $0.opportunityID == opportunityId },
            sortBy: [SortDescriptor(\.order)]
        )
        let models = try context.fetch(descriptor)
        let lookup = Dictionary(uniqueKeysWithValues: models.map { ($0.id, $0) })
        for (index, stageId) in orderedStageIds.enumerated() {
            if let model = lookup[stageId] {
                model.order = index
            }
        }
        let provided = Set(orderedStageIds)
        var trailingIndex = orderedStageIds.count
        for model in models where !provided.contains(model.id) {
            model.order = trailingIndex
            trailingIndex += 1
        }
        try context.save()
    }
    private func fetchStageModel(id: UUID) throws -> SDStage? {
        let descriptor = FetchDescriptor<SDStage>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first
    }
    private func fetchOpportunityModel(id: UUID) throws -> SDOpportunity? {
        let descriptor = FetchDescriptor<SDOpportunity>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first
    }
}
public final class SwiftDataCardRepository: CardRepository {
    private let context: ModelContext
    public init(context: ModelContext) {
        self.context = context
    }
    public func list(opportunityId: UUID) throws -> [ProcessCard] {
        let descriptor = FetchDescriptor<SDCard>(
            predicate: #Predicate { $0.opportunityID == opportunityId },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map { $0.toDomain() }
    }
    public func list(stageId: UUID) throws -> [ProcessCard] {
        let descriptor = FetchDescriptor<SDCard>(
            predicate: #Predicate { $0.stageID == stageId },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map { $0.toDomain() }
    }
    public func fetch(id: UUID) throws -> ProcessCard? {
        let descriptor = FetchDescriptor<SDCard>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first?.toDomain()
    }
    public func create(_ card: ProcessCard) throws {
        guard let opportunity = try fetchOpportunityModel(id: card.opportunityId) else {
            throw RepositoryError.validation("Cannot create card: opportunity not found.")
        }
        guard let stage = try fetchStageModel(id: card.stageId) else {
            throw RepositoryError.validation("Cannot create card: stage not found.")
        }
        guard stage.opportunityID == opportunity.id else {
            throw RepositoryError.validation("Stage does not belong to this opportunity.")
        }
        let model = SDCard(
            id: card.id,
            opportunityID: card.opportunityId,
            stageID: card.stageId,
            title: card.title,
            kindRawValue: card.kind.rawValue,
            statusRawValue: card.status.rawValue,
            scheduledAt: card.scheduledAt,
            durationMinutes: card.durationMinutes,
            peopleBlob: BlobCoder.encode(card.people),
            debriefBlob: BlobCoder.encode(card.debrief),
            externalLinksBlob: BlobCoder.encode(card.externalLinks.map(\.absoluteString)),
            calendarEventIdentifier: card.calendarEventIdentifier,
            notificationRequestIdentifier: card.notificationRequestIdentifier,
            createdAt: card.createdAt,
            updatedAt: card.updatedAt,
            opportunity: opportunity,
            stage: stage
        )
        context.insert(model)
        try context.save()
    }
    public func update(_ card: ProcessCard) throws {
        guard let model = try fetchCardModel(id: card.id) else {
            throw RepositoryError.notFound
        }
        guard let opportunity = try fetchOpportunityModel(id: card.opportunityId) else {
            throw RepositoryError.validation("Cannot update card: opportunity not found.")
        }
        guard let stage = try fetchStageModel(id: card.stageId) else {
            throw RepositoryError.validation("Cannot update card: stage not found.")
        }
        guard stage.opportunityID == opportunity.id else {
            throw RepositoryError.validation("Stage does not belong to this opportunity.")
        }
        model.apply(card)
        model.opportunity = opportunity
        model.stage = stage
        model.opportunityID = opportunity.id
        model.stageID = stage.id
        try context.save()
    }
    public func delete(id: UUID) throws {
        guard let model = try fetchCardModel(id: id) else {
            throw RepositoryError.notFound
        }
        context.delete(model)
        try context.save()
    }
    public func move(cardId: UUID, to stageId: UUID) throws {
        guard let card = try fetchCardModel(id: cardId) else {
            throw RepositoryError.notFound
        }
        guard let stage = try fetchStageModel(id: stageId) else {
            throw RepositoryError.validation("Stage not found.")
        }
        card.stage = stage
        card.stageID = stage.id
        card.updatedAt = Date()
        try context.save()
    }
    public func search(query: String, opportunityId: UUID?) throws -> [ProcessCard] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalized.isEmpty {
            if let opportunityId {
                return try list(opportunityId: opportunityId)
            }
            let descriptor = FetchDescriptor<SDCard>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
            return try context.fetch(descriptor).map { $0.toDomain() }
        }
        let descriptor = FetchDescriptor<SDCard>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        let all = try context.fetch(descriptor)
        return all.compactMap { model in
            if let opportunityId, model.opportunityID != opportunityId {
                return nil
            }
            if model.title.lowercased().contains(normalized) {
                return model.toDomain()
            }
            return nil
        }
    }
    private func fetchCardModel(id: UUID) throws -> SDCard? {
        let descriptor = FetchDescriptor<SDCard>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first
    }
    private func fetchOpportunityModel(id: UUID) throws -> SDOpportunity? {
        let descriptor = FetchDescriptor<SDOpportunity>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first
    }
    private func fetchStageModel(id: UUID) throws -> SDStage? {
        let descriptor = FetchDescriptor<SDStage>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first
    }
}
public final class SwiftDataQuestionRepository: QuestionRepository {
    private let context: ModelContext
    public init(context: ModelContext) {
        self.context = context
    }
    public func list(search query: String?, tagNames: [String]) throws -> [Question] {
        let descriptor = FetchDescriptor<SDQuestion>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        let all = try context.fetch(descriptor)
        let normalizedQuery = query?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        let normalizedTags = Set(tagNames.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }.filter { !$0.isEmpty })
        return all.compactMap { model in
            let question = model.toDomain()
            if !normalizedQuery.isEmpty && !question.text.lowercased().contains(normalizedQuery) {
                return nil
            }
            if !normalizedTags.isEmpty {
                let names = Set(question.tags.map { $0.name.lowercased() })
                if !normalizedTags.isSubset(of: names) {
                    return nil
                }
            }
            return question
        }
    }
    public func fetch(id: UUID) throws -> Question? {
        let descriptor = FetchDescriptor<SDQuestion>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first?.toDomain()
    }
    public func create(_ question: Question) throws {
        let model = SDQuestion(
            id: question.id,
            text: question.text,
            difficulty: question.difficulty,
            notes: question.notes,
            createdAt: question.createdAt,
            updatedAt: question.updatedAt
        )
        model.tags = try resolvedTags(for: question.tags)
        context.insert(model)
        try context.save()
    }
    public func update(_ question: Question) throws {
        guard let model = try fetchQuestionModel(id: question.id) else {
            throw RepositoryError.notFound
        }
        model.apply(question)
        model.tags = try resolvedTags(for: question.tags)
        try context.save()
    }
    public func delete(id: UUID) throws {
        guard let model = try fetchQuestionModel(id: id) else {
            throw RepositoryError.notFound
        }
        context.delete(model)
        try context.save()
    }
    public func search(query: String) throws -> [Question] {
        try list(search: query, tagNames: [])
    }
    public func allTags() throws -> [Tag] {
        let descriptor = FetchDescriptor<SDTag>(sortBy: [SortDescriptor(\.name)])
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    public func searchTags(query: String) throws -> [Tag] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let tags = try allTags()
        guard !normalized.isEmpty else { return tags }
        return tags.filter { $0.name.lowercased().contains(normalized) }
    }
    public func upsertTag(named name: String) throws -> Tag {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedName.isEmpty else {
            throw RepositoryError.validation("Tag name cannot be empty.")
        }
        if let existing = try fetchTagModel(byName: normalizedName) {
            return existing.toDomain()
        }
        let tag = SDTag(id: UUID(), name: normalizedName)
        context.insert(tag)
        try context.save()
        return tag.toDomain()
    }
    private func fetchQuestionModel(id: UUID) throws -> SDQuestion? {
        let descriptor = FetchDescriptor<SDQuestion>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first
    }
    private func fetchTagModel(id: UUID) throws -> SDTag? {
        let descriptor = FetchDescriptor<SDTag>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first
    }
    private func fetchTagModel(byName name: String) throws -> SDTag? {
        let descriptor = FetchDescriptor<SDTag>(sortBy: [SortDescriptor(\.name)])
        let all = try context.fetch(descriptor)
        return all.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }
    private func resolvedTags(for tags: [Tag]) throws -> [SDTag] {
        var models: [SDTag] = []
        for tag in tags {
            if let byId = try fetchTagModel(id: tag.id) {
                byId.name = tag.name
                models.append(byId)
                continue
            }
            if let byName = try fetchTagModel(byName: tag.name) {
                models.append(byName)
                continue
            }
            let newTag = SDTag(id: tag.id, name: tag.name)
            context.insert(newTag)
            models.append(newTag)
        }
        return models
    }
}
public final class SwiftDataPersonRepository: PersonRepository {
    private let context: ModelContext
    public init(context: ModelContext) {
        self.context = context
    }
    public func list(search query: String?) throws -> [Person] {
        let descriptor = FetchDescriptor<SDPerson>(sortBy: [SortDescriptor(\.name)])
        let all = try context.fetch(descriptor)
        let needle = query?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        if needle.isEmpty {
            return all.map { $0.toDomain() }
        }
        return all
            .filter { $0.name.lowercased().contains(needle) }
            .map { $0.toDomain() }
    }
    public func fetch(id: UUID) throws -> Person? {
        let descriptor = FetchDescriptor<SDPerson>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first?.toDomain()
    }
    public func create(_ person: Person) throws {
        let model = SDPerson(
            id: person.id,
            name: person.name,
            roleRawValue: person.role.rawValue,
            email: person.email,
            phone: person.phone,
            notes: person.notes
        )
        context.insert(model)
        try context.save()
    }
    public func update(_ person: Person) throws {
        guard let model = try fetchPersonModel(id: person.id) else {
            throw RepositoryError.notFound
        }
        model.apply(person)
        try context.save()
    }
    public func delete(id: UUID) throws {
        guard let model = try fetchPersonModel(id: id) else {
            throw RepositoryError.notFound
        }
        context.delete(model)
        try context.save()
    }
    private func fetchPersonModel(id: UUID) throws -> SDPerson? {
        let descriptor = FetchDescriptor<SDPerson>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first
    }
}
public final class AppleAppServices: AppServices {
    public let opportunities: OpportunityRepository
    public let stages: StageRepository
    public let cards: CardRepository
    public let questions: QuestionRepository
    public let people: PersonRepository
    public init(context: ModelContext) {
        self.opportunities = SwiftDataOpportunityRepository(context: context)
        self.stages = SwiftDataStageRepository(context: context)
        self.cards = SwiftDataCardRepository(context: context)
        self.questions = SwiftDataQuestionRepository(context: context)
        self.people = SwiftDataPersonRepository(context: context)
    }
}
