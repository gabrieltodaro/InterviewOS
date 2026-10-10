import Foundation

public struct Company: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var websiteURL: URL?

    public init(
        id: UUID = UUID(),
        name: String,
        websiteURL: URL? = nil
    ) {
        self.id = id
        self.name = name
        self.websiteURL = websiteURL
    }
}

public enum WorkMode: String, Codable, CaseIterable, Hashable, Sendable {
    case onsite
    case hybrid
    case remote
    case unknown

    public var displayName: String {
        switch self {
        case .onsite:
            "On-site"
        case .hybrid:
            "Hybrid"
        case .remote:
            "Remote"
        case .unknown:
            "Unknown"
        }
    }
}

public struct Opportunity: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var companyId: UUID
    public var roleTitle: String
    public var location: String
    public var workMode: WorkMode
    public var salaryRange: String?
    public var benefitsNotes: String?
    public var jobDescription: String
    public var notes: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        companyId: UUID,
        roleTitle: String,
        location: String = "",
        workMode: WorkMode = .unknown,
        salaryRange: String? = nil,
        benefitsNotes: String? = nil,
        jobDescription: String,
        notes: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.companyId = companyId
        self.roleTitle = roleTitle
        self.location = location
        self.workMode = workMode
        self.salaryRange = salaryRange
        self.benefitsNotes = benefitsNotes
        self.jobDescription = jobDescription
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct Stage: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var opportunityId: UUID
    public var title: String
    public var order: Int
    public var isClosedColumn: Bool

    public init(
        id: UUID = UUID(),
        opportunityId: UUID,
        title: String,
        order: Int,
        isClosedColumn: Bool = false
    ) {
        self.id = id
        self.opportunityId = opportunityId
        self.title = title
        self.order = order
        self.isClosedColumn = isClosedColumn
    }
}

public struct PersonRef: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var name: String

    public init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

public struct QuestionRef: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var text: String

    public init(id: UUID = UUID(), text: String) {
        self.id = id
        self.text = text
    }
}

public enum ProcessCardKind: String, Codable, CaseIterable, Hashable, Sendable {
    case generic
    case hr
    case coding
    case systemDesign
    case behavioral
    case takeHome
    case onsite
    case other

    public var displayName: String {
        switch self {
        case .generic:
            "Generic"
        case .hr:
            "HR"
        case .coding:
            "Coding"
        case .systemDesign:
            "System Design"
        case .behavioral:
            "Behavioral"
        case .takeHome:
            "Take-home"
        case .onsite:
            "Onsite"
        case .other:
            "Other"
        }
    }
}

public enum ProcessCardStatus: String, Codable, CaseIterable, Hashable, Sendable {
    case planned
    case scheduled
    case completed
    case passed
    case failed
    case unknown

    public var displayName: String {
        rawValue.capitalized
    }
}

public struct Debrief: Codable, Hashable, Sendable {
    public var summary: String
    public var questions: [QuestionRef]
    public var whatWentWell: String
    public var gaps: String
    public var nextActions: [String]
    public var confidence: Int

    public init(
        summary: String = "",
        questions: [QuestionRef] = [],
        whatWentWell: String = "",
        gaps: String = "",
        nextActions: [String] = [],
        confidence: Int = 0
    ) {
        self.summary = summary
        self.questions = questions
        self.whatWentWell = whatWentWell
        self.gaps = gaps
        self.nextActions = nextActions
        self.confidence = max(0, min(5, confidence))
    }
}

public struct ProcessCard: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var opportunityId: UUID
    public var stageId: UUID
    public var title: String
    public var kind: ProcessCardKind
    public var status: ProcessCardStatus
    public var scheduledAt: Date?
    public var durationMinutes: Int?
    public var people: [PersonRef]
    public var debrief: Debrief
    public var externalLinks: [URL]
    public var calendarEventIdentifier: String?
    public var notificationRequestIdentifier: String?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        opportunityId: UUID,
        stageId: UUID,
        title: String,
        kind: ProcessCardKind = .generic,
        status: ProcessCardStatus = .planned,
        scheduledAt: Date? = nil,
        durationMinutes: Int? = nil,
        people: [PersonRef] = [],
        debrief: Debrief = Debrief(),
        externalLinks: [URL] = [],
        calendarEventIdentifier: String? = nil,
        notificationRequestIdentifier: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.opportunityId = opportunityId
        self.stageId = stageId
        self.title = title
        self.kind = kind
        self.status = status
        self.scheduledAt = scheduledAt
        self.durationMinutes = durationMinutes
        self.people = people
        self.debrief = debrief
        self.externalLinks = externalLinks
        self.calendarEventIdentifier = calendarEventIdentifier
        self.notificationRequestIdentifier = notificationRequestIdentifier
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct Tag: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var name: String

    public init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

public struct Question: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var text: String
    public var tags: [Tag]
    public var difficulty: Int
    public var notes: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        text: String,
        tags: [Tag] = [],
        difficulty: Int = 1,
        notes: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.tags = tags
        self.difficulty = max(1, min(5, difficulty))
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public enum PersonRole: String, Codable, CaseIterable, Hashable, Sendable {
    case recruiter
    case interviewer
    case hiringManager
    case coordinator
    case other

    public var displayName: String {
        switch self {
        case .recruiter:
            "Recruiter"
        case .interviewer:
            "Interviewer"
        case .hiringManager:
            "Hiring Manager"
        case .coordinator:
            "Coordinator"
        case .other:
            "Other"
        }
    }
}

public struct Person: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var role: PersonRole
    public var email: String?
    public var phone: String?
    public var notes: String?

    public init(
        id: UUID = UUID(),
        name: String,
        role: PersonRole = .interviewer,
        email: String? = nil,
        phone: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.email = email
        self.phone = phone
        self.notes = notes
    }
}

public struct Offer: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var opportunityId: UUID
    public var baseSalary: String
    public var equity: String
    public var bonus: String
    public var notes: String
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        opportunityId: UUID,
        baseSalary: String = "",
        equity: String = "",
        bonus: String = "",
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.opportunityId = opportunityId
        self.baseSalary = baseSalary
        self.equity = equity
        self.bonus = bonus
        self.notes = notes
        self.createdAt = createdAt
    }
}

public enum DomainTemplates {
    public static let defaultCardKinds: [ProcessCardKind] = ProcessCardKind.allCases

    public static func defaultStages(for opportunityId: UUID) -> [Stage] {
        [
            Stage(opportunityId: opportunityId, title: "Applied", order: 0),
            Stage(opportunityId: opportunityId, title: "Scheduling", order: 1),
            Stage(opportunityId: opportunityId, title: "Interviewing", order: 2),
            Stage(opportunityId: opportunityId, title: "Waiting", order: 3),
            Stage(opportunityId: opportunityId, title: "Offer", order: 4),
            Stage(opportunityId: opportunityId, title: "Closed", order: 5, isClosedColumn: true)
        ]
    }
}
