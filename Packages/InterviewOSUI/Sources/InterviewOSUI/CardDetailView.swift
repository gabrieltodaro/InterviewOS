import SwiftUI
import InterviewOSDomain
import InterviewOSPersistence

public struct CardDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appServices) private var services
    @Environment(\.interviewScheduler) private var scheduler

    private let cardID: UUID
    private let opportunity: Opportunity
    private let company: Company
    private let onSaved: () -> Void

    @State private var loadedCard: ProcessCard?
    @State private var title = ""
    @State private var kind: ProcessCardKind = .generic
    @State private var status: ProcessCardStatus = .planned
    @State private var hasSchedule = false
    @State private var scheduledAt = Date()
    @State private var durationMinutes = 60
    @State private var people: [PersonRef] = []
    @State private var externalLinkStrings: [String] = []

    @State private var summary = ""
    @State private var linkedQuestions: [QuestionRef] = []
    @State private var whatWentWell = ""
    @State private var gaps = ""
    @State private var nextActions: [String] = []
    @State private var confidence = 0.0

    @State private var allQuestions: [Question] = []
    @State private var selectedQuestionID: UUID?
    @State private var newInlineQuestionText = ""
    @State private var newInlineQuestionTags = ""
    @State private var newPersonName = ""
    @State private var newExternalLink = ""
    @State private var newNextAction = ""

    @State private var infoMessage: String?
    @State private var errorMessage: String?

    public init(cardID: UUID, opportunity: Opportunity, company: Company, onSaved: @escaping () -> Void) {
        self.cardID = cardID
        self.opportunity = opportunity
        self.company = company
        self.onSaved = onSaved
    }

    public var body: some View {
        Form {
            Section("Card") {
                TextField("Title", text: $title)

                Picker("Kind", selection: $kind) {
                    ForEach(ProcessCardKind.allCases, id: \.self) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }

                Picker("Status", selection: $status) {
                    ForEach(ProcessCardStatus.allCases, id: \.self) { status in
                        Text(status.displayName).tag(status)
                    }
                }

                Toggle("Scheduled", isOn: $hasSchedule)

                if hasSchedule {
                    DatePicker("Date & Time", selection: $scheduledAt)
                    Stepper("Duration: \(durationMinutes) min", value: $durationMinutes, in: 15...360, step: 15)
                }
            }

            Section("People") {
                ForEach($people) { $person in
                    TextField("Name", text: $person.name)
                }
                .onDelete { indexes in
                    people.remove(atOffsets: indexes)
                }

                HStack {
                    TextField("Add person", text: $newPersonName)
                    Button("Add") {
                        let trimmed = newPersonName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        people.append(PersonRef(name: trimmed))
                        newPersonName = ""
                    }
                }
            }

            Section("External Links") {
                ForEach(Array(externalLinkStrings.enumerated()), id: \.offset) { index, _ in
                    TextField("https://", text: Binding(
                        get: { externalLinkStrings[index] },
                        set: { externalLinkStrings[index] = $0 }
                    ))
                }
                .onDelete { indexes in
                    externalLinkStrings.remove(atOffsets: indexes)
                }

                HStack {
                    TextField("https://", text: $newExternalLink)
                    Button("Add") {
                        let trimmed = newExternalLink.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        externalLinkStrings.append(trimmed)
                        newExternalLink = ""
                    }
                }
            }

            Section("Debrief") {
                TextField("Summary", text: $summary, axis: .vertical)
                TextField("What went well", text: $whatWentWell, axis: .vertical)
                TextField("Gaps", text: $gaps, axis: .vertical)

                ForEach(Array(nextActions.enumerated()), id: \.offset) { index, _ in
                    TextField("Next action", text: Binding(
                        get: { nextActions[index] },
                        set: { nextActions[index] = $0 }
                    ))
                }
                .onDelete { indexes in
                    nextActions.remove(atOffsets: indexes)
                }

                HStack {
                    TextField("Add next action", text: $newNextAction)
                    Button("Add") {
                        let trimmed = newNextAction.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        nextActions.append(trimmed)
                        newNextAction = ""
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Confidence: \(Int(confidence.rounded())) / 5")
                    Slider(value: $confidence, in: 0...5, step: 1)
                }
            }

            Section("Questions") {
                if linkedQuestions.isEmpty {
                    Text("No linked questions yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(linkedQuestions) { question in
                        HStack {
                            Text(question.text)
                            Spacer()
                            Button(role: .destructive) {
                                linkedQuestions.removeAll { $0.id == question.id }
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                }

                Picker("Link existing", selection: $selectedQuestionID) {
                    Text("Select question").tag(UUID?.none)
                    ForEach(allQuestions) { question in
                        Text(question.text).tag(Optional(question.id))
                    }
                }

                Button("Link Selected") {
                    linkSelectedQuestion()
                }
                .disabled(selectedQuestionID == nil)

                TextField("Create new question", text: $newInlineQuestionText, axis: .vertical)
                TextField("Tags (comma separated)", text: $newInlineQuestionTags)

                Button("Create & Link") {
                    createQuestionInline()
                }
                .disabled(newInlineQuestionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if hasSchedule {
                Section("Scheduling") {
                    Button("Add to Calendar") {
                        Task {
                            await addToCalendar()
                        }
                    }

                    Button("Schedule Notification") {
                        Task {
                            await scheduleNotification()
                        }
                    }
                }
            }
        }
        .navigationTitle("Card Detail")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
            }
        }
        .task {
            load()
        }
        .alert("Info", isPresented: Binding(
            get: { infoMessage != nil },
            set: { show in
                if !show { infoMessage = nil }
            }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(infoMessage ?? "")
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { show in
                if !show { errorMessage = nil }
            }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func load() {
        do {
            guard let card = try services.cards.fetch(id: cardID) else {
                errorMessage = "Card not found."
                return
            }

            loadedCard = card
            title = card.title
            kind = card.kind
            status = card.status
            hasSchedule = card.scheduledAt != nil
            scheduledAt = card.scheduledAt ?? Date()
            durationMinutes = card.durationMinutes ?? 60
            people = card.people
            externalLinkStrings = card.externalLinks.map(\.absoluteString)

            summary = card.debrief.summary
            linkedQuestions = card.debrief.questions
            whatWentWell = card.debrief.whatWentWell
            gaps = card.debrief.gaps
            nextActions = card.debrief.nextActions
            confidence = Double(card.debrief.confidence)

            allQuestions = try services.questions.list(search: nil, tagNames: [])
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func linkSelectedQuestion() {
        guard let selectedQuestionID,
              let question = allQuestions.first(where: { $0.id == selectedQuestionID }) else {
            return
        }

        if !linkedQuestions.contains(where: { $0.id == question.id }) {
            linkedQuestions.append(QuestionRef(id: question.id, text: question.text))
        }

        self.selectedQuestionID = nil
    }

    private func createQuestionInline() {
        do {
            let trimmedText = newInlineQuestionText.trimmingCharacters(in: .whitespacesAndNewlines)
            let tagNames = newInlineQuestionTags
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            let tags = try tagNames.map { name in
                try services.questions.upsertTag(named: name)
            }

            let question = Question(
                text: trimmedText,
                tags: tags,
                difficulty: 3,
                notes: ""
            )
            try services.questions.create(question)
            allQuestions = try services.questions.list(search: nil, tagNames: [])
            linkedQuestions.append(QuestionRef(id: question.id, text: question.text))
            newInlineQuestionText = ""
            newInlineQuestionTags = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func save() {
        guard var card = loadedCard else {
            errorMessage = "Card not loaded."
            return
        }

        do {
            card.title = title
            card.kind = kind
            card.status = status
            card.scheduledAt = hasSchedule ? scheduledAt : nil
            card.durationMinutes = hasSchedule ? durationMinutes : nil
            card.people = people.filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            card.externalLinks = externalLinkStrings.compactMap { URL(string: $0) }
            card.debrief = Debrief(
                summary: summary,
                questions: linkedQuestions,
                whatWentWell: whatWentWell,
                gaps: gaps,
                nextActions: nextActions.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
                confidence: Int(confidence.rounded())
            )
            card.updatedAt = Date()

            try services.cards.update(card)
            loadedCard = card
            onSaved()
            infoMessage = "Saved"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func addToCalendar() async {
        guard var card = loadedCard else {
            errorMessage = "Card not loaded."
            return
        }
        guard hasSchedule else {
            errorMessage = "Set a date/time first."
            return
        }

        do {
            card.title = title
            card.scheduledAt = scheduledAt
            card.durationMinutes = durationMinutes
            let eventID = try await scheduler.upsertCalendarEvent(
                for: card,
                opportunity: opportunity,
                company: company
            )
            card.calendarEventIdentifier = eventID
            card.updatedAt = Date()
            try services.cards.update(card)
            loadedCard = card
            onSaved()
            infoMessage = "Calendar event updated"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func scheduleNotification() async {
        guard var card = loadedCard else {
            errorMessage = "Card not loaded."
            return
        }
        guard hasSchedule else {
            errorMessage = "Set a date/time first."
            return
        }

        do {
            card.title = title
            card.scheduledAt = scheduledAt
            let notificationID = try await scheduler.scheduleNotification(
                for: card,
                opportunity: opportunity,
                company: company
            )
            card.notificationRequestIdentifier = notificationID
            card.updatedAt = Date()
            try services.cards.update(card)
            loadedCard = card
            onSaved()
            infoMessage = "Notification scheduled"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    let services = MockAppServices.preview
    let opportunity = (try? services.opportunities.list(search: nil).first) ?? Opportunity(companyId: UUID(), roleTitle: "Role", jobDescription: "JD")
    let company = (try? services.opportunities.fetchCompany(id: opportunity.companyId)) ?? Company(id: opportunity.companyId, name: "Acme")
    let card = (try? services.cards.list(opportunityId: opportunity.id).first) ?? ProcessCard(opportunityId: opportunity.id, stageId: UUID(), title: "Card")

    return NavigationStack {
        CardDetailView(cardID: card.id, opportunity: opportunity, company: company, onSaved: {})
    }
    .appServices(services)
    .interviewScheduler(MockInterviewScheduler())
}
