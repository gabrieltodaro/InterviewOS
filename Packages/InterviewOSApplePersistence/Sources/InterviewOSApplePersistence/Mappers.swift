import Foundation
import InterviewOSDomain

enum BlobCoder {
    static let encoder = JSONEncoder()
    static let decoder = JSONDecoder()

    static func encode<T: Encodable>(_ value: T) -> Data {
        (try? encoder.encode(value)) ?? Data()
    }

    static func decode<T: Decodable>(_ type: T.Type, from data: Data, fallback: T) -> T {
        (try? decoder.decode(type, from: data)) ?? fallback
    }
}

extension SDCompany {
    func toDomain() -> Company {
        Company(
            id: id,
            name: name,
            websiteURL: websiteURLString.flatMap(URL.init(string:))
        )
    }

    func apply(_ company: Company) {
        id = company.id
        name = company.name
        websiteURLString = company.websiteURL?.absoluteString
    }
}

extension SDOpportunity {
    func toDomain() -> Opportunity {
        Opportunity(
            id: id,
            companyId: companyID,
            roleTitle: roleTitle,
            location: location,
            workMode: WorkMode(rawValue: workModeRawValue) ?? .unknown,
            salaryRange: salaryRange,
            benefitsNotes: benefitsNotes,
            jobDescription: jobDescription,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func apply(_ opportunity: Opportunity) {
        id = opportunity.id
        companyID = opportunity.companyId
        roleTitle = opportunity.roleTitle
        location = opportunity.location
        workModeRawValue = opportunity.workMode.rawValue
        salaryRange = opportunity.salaryRange
        benefitsNotes = opportunity.benefitsNotes
        jobDescription = opportunity.jobDescription
        notes = opportunity.notes
        createdAt = opportunity.createdAt
        updatedAt = opportunity.updatedAt
    }
}

extension SDStage {
    func toDomain() -> Stage {
        Stage(
            id: id,
            opportunityId: opportunityID,
            title: title,
            order: order,
            isClosedColumn: isClosedColumn
        )
    }

    func apply(_ stage: Stage) {
        id = stage.id
        opportunityID = stage.opportunityId
        title = stage.title
        order = stage.order
        isClosedColumn = stage.isClosedColumn
    }
}

extension SDCard {
    func toDomain() -> ProcessCard {
        let links: [String] = BlobCoder.decode([String].self, from: externalLinksBlob, fallback: [])

        return ProcessCard(
            id: id,
            opportunityId: opportunityID,
            stageId: stageID,
            title: title,
            kind: ProcessCardKind(rawValue: kindRawValue) ?? .generic,
            status: ProcessCardStatus(rawValue: statusRawValue) ?? .unknown,
            scheduledAt: scheduledAt,
            durationMinutes: durationMinutes,
            people: BlobCoder.decode([PersonRef].self, from: peopleBlob, fallback: []),
            debrief: BlobCoder.decode(Debrief.self, from: debriefBlob, fallback: Debrief()),
            externalLinks: links.compactMap(URL.init(string:)),
            calendarEventIdentifier: calendarEventIdentifier,
            notificationRequestIdentifier: notificationRequestIdentifier,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func apply(_ card: ProcessCard) {
        id = card.id
        opportunityID = card.opportunityId
        stageID = card.stageId
        title = card.title
        kindRawValue = card.kind.rawValue
        statusRawValue = card.status.rawValue
        scheduledAt = card.scheduledAt
        durationMinutes = card.durationMinutes
        peopleBlob = BlobCoder.encode(card.people)
        debriefBlob = BlobCoder.encode(card.debrief)
        externalLinksBlob = BlobCoder.encode(card.externalLinks.map(\.absoluteString))
        calendarEventIdentifier = card.calendarEventIdentifier
        notificationRequestIdentifier = card.notificationRequestIdentifier
        createdAt = card.createdAt
        updatedAt = card.updatedAt
    }
}

extension SDTag {
    func toDomain() -> Tag {
        Tag(id: id, name: name)
    }
}

extension SDQuestion {
    func toDomain() -> Question {
        Question(
            id: id,
            text: text,
            tags: tags.map { $0.toDomain() },
            difficulty: difficulty,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func apply(_ question: Question) {
        id = question.id
        text = question.text
        difficulty = question.difficulty
        notes = question.notes
        createdAt = question.createdAt
        updatedAt = question.updatedAt
    }
}

extension SDPerson {
    func toDomain() -> Person {
        Person(
            id: id,
            name: name,
            role: PersonRole(rawValue: roleRawValue) ?? .other,
            email: email,
            phone: phone,
            notes: notes
        )
    }

    func apply(_ person: Person) {
        id = person.id
        name = person.name
        roleRawValue = person.role.rawValue
        email = person.email
        phone = person.phone
        notes = person.notes
    }
}
