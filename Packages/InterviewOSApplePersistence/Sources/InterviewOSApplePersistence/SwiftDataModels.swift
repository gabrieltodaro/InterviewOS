import Foundation
import SwiftData

@Model
public final class SDCompany {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var websiteURLString: String?

    public init(
        id: UUID,
        name: String,
        websiteURLString: String? = nil
    ) {
        self.id = id
        self.name = name
        self.websiteURLString = websiteURLString
    }
}

@Model
public final class SDOpportunity {
    @Attribute(.unique) public var id: UUID
    public var companyID: UUID
    public var roleTitle: String
    public var location: String
    public var workModeRawValue: String
    public var salaryRange: String?
    public var benefitsNotes: String?
    public var jobDescription: String
    public var notes: String
    public var createdAt: Date
    public var updatedAt: Date

    public var company: SDCompany?

    public init(
        id: UUID,
        companyID: UUID,
        roleTitle: String,
        location: String,
        workModeRawValue: String,
        salaryRange: String?,
        benefitsNotes: String?,
        jobDescription: String,
        notes: String,
        createdAt: Date,
        updatedAt: Date,
        company: SDCompany? = nil
    ) {
        self.id = id
        self.companyID = companyID
        self.roleTitle = roleTitle
        self.location = location
        self.workModeRawValue = workModeRawValue
        self.salaryRange = salaryRange
        self.benefitsNotes = benefitsNotes
        self.jobDescription = jobDescription
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.company = company
    }
}

@Model
public final class SDStage {
    @Attribute(.unique) public var id: UUID
    public var opportunityID: UUID
    public var title: String
    public var order: Int
    public var isClosedColumn: Bool

    public var opportunity: SDOpportunity?

    public init(
        id: UUID,
        opportunityID: UUID,
        title: String,
        order: Int,
        isClosedColumn: Bool,
        opportunity: SDOpportunity? = nil
    ) {
        self.id = id
        self.opportunityID = opportunityID
        self.title = title
        self.order = order
        self.isClosedColumn = isClosedColumn
        self.opportunity = opportunity
    }
}

@Model
public final class SDCard {
    @Attribute(.unique) public var id: UUID
    public var opportunityID: UUID
    public var stageID: UUID
    public var title: String
    public var kindRawValue: String
    public var statusRawValue: String
    public var scheduledAt: Date?
    public var durationMinutes: Int?
    public var peopleBlob: Data
    public var debriefBlob: Data
    public var externalLinksBlob: Data
    public var calendarEventIdentifier: String?
    public var notificationRequestIdentifier: String?
    public var createdAt: Date
    public var updatedAt: Date

    public var opportunity: SDOpportunity?
    public var stage: SDStage?

    public init(
        id: UUID,
        opportunityID: UUID,
        stageID: UUID,
        title: String,
        kindRawValue: String,
        statusRawValue: String,
        scheduledAt: Date?,
        durationMinutes: Int?,
        peopleBlob: Data,
        debriefBlob: Data,
        externalLinksBlob: Data,
        calendarEventIdentifier: String?,
        notificationRequestIdentifier: String?,
        createdAt: Date,
        updatedAt: Date,
        opportunity: SDOpportunity? = nil,
        stage: SDStage? = nil
    ) {
        self.id = id
        self.opportunityID = opportunityID
        self.stageID = stageID
        self.title = title
        self.kindRawValue = kindRawValue
        self.statusRawValue = statusRawValue
        self.scheduledAt = scheduledAt
        self.durationMinutes = durationMinutes
        self.peopleBlob = peopleBlob
        self.debriefBlob = debriefBlob
        self.externalLinksBlob = externalLinksBlob
        self.calendarEventIdentifier = calendarEventIdentifier
        self.notificationRequestIdentifier = notificationRequestIdentifier
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.opportunity = opportunity
        self.stage = stage
    }
}

@Model
public final class SDTag {
    @Attribute(.unique) public var id: UUID
    public var name: String

    public init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }
}

@Model
public final class SDQuestion {
    @Attribute(.unique) public var id: UUID
    public var text: String
    public var difficulty: Int
    public var notes: String
    public var createdAt: Date
    public var updatedAt: Date

    public var tags: [SDTag]

    public init(
        id: UUID,
        text: String,
        difficulty: Int,
        notes: String,
        createdAt: Date,
        updatedAt: Date,
        tags: [SDTag] = []
    ) {
        self.id = id
        self.text = text
        self.difficulty = difficulty
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tags = tags
    }
}

@Model
public final class SDPerson {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var roleRawValue: String
    public var email: String?
    public var phone: String?
    public var notes: String?

    public init(
        id: UUID,
        name: String,
        roleRawValue: String,
        email: String?,
        phone: String?,
        notes: String?
    ) {
        self.id = id
        self.name = name
        self.roleRawValue = roleRawValue
        self.email = email
        self.phone = phone
        self.notes = notes
    }
}
