import SwiftUI
import InterviewOSDomain
import InterviewOSPersistence

public struct OpportunityEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appServices) private var services

    private let existingOpportunity: Opportunity?
    private let existingCompany: Company?
    private let onSaved: (Opportunity) -> Void

    @State private var companyName: String
    @State private var roleTitle: String
    @State private var location: String
    @State private var workMode: WorkMode
    @State private var salaryRange: String
    @State private var benefitsNotes: String
    @State private var jobDescription: String
    @State private var notes: String
    @State private var errorMessage: String?

    public init(
        existingOpportunity: Opportunity? = nil,
        existingCompany: Company? = nil,
        onSaved: @escaping (Opportunity) -> Void
    ) {
        self.existingOpportunity = existingOpportunity
        self.existingCompany = existingCompany
        self.onSaved = onSaved

        _companyName = State(initialValue: existingCompany?.name ?? "")
        _roleTitle = State(initialValue: existingOpportunity?.roleTitle ?? "")
        _location = State(initialValue: existingOpportunity?.location ?? "")
        _workMode = State(initialValue: existingOpportunity?.workMode ?? .unknown)
        _salaryRange = State(initialValue: existingOpportunity?.salaryRange ?? "")
        _benefitsNotes = State(initialValue: existingOpportunity?.benefitsNotes ?? "")
        _jobDescription = State(initialValue: existingOpportunity?.jobDescription ?? "")
        _notes = State(initialValue: existingOpportunity?.notes ?? "")
    }

    public var body: some View {
        Form {
            Section("Role") {
                TextField("Company", text: $companyName)
                TextField("Role Title", text: $roleTitle)
                TextField("Location", text: $location)
                Picker("Work Mode", selection: $workMode) {
                    ForEach(WorkMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                TextField("Salary Range", text: $salaryRange)
            }

            Section("Job Description") {
                TextEditor(text: $jobDescription)
                    .frame(minHeight: 180)
            }

            Section("Benefits") {
                TextEditor(text: $benefitsNotes)
                    .frame(minHeight: 100)
            }

            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 120)
            }
        }
        .navigationTitle(existingOpportunity == nil ? "New Opportunity" : "Edit Opportunity")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .disabled(companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || roleTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || jobDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
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

    private func save() {
        do {
            let company = try services.opportunities.upsertCompany(
                named: companyName,
                websiteURL: existingCompany?.websiteURL
            )

            if var current = existingOpportunity {
                current.companyId = company.id
                current.roleTitle = roleTitle
                current.location = location
                current.workMode = workMode
                current.salaryRange = emptyToNil(salaryRange)
                current.benefitsNotes = emptyToNil(benefitsNotes)
                current.jobDescription = jobDescription
                current.notes = notes
                current.updatedAt = Date()
                try services.opportunities.update(current)
                onSaved(current)
            } else {
                let opportunity = Opportunity(
                    companyId: company.id,
                    roleTitle: roleTitle,
                    location: location,
                    workMode: workMode,
                    salaryRange: emptyToNil(salaryRange),
                    benefitsNotes: emptyToNil(benefitsNotes),
                    jobDescription: jobDescription,
                    notes: notes
                )
                try services.opportunities.create(opportunity)
                for stage in DomainTemplates.defaultStages(for: opportunity.id) {
                    try services.stages.create(stage)
                }
                onSaved(opportunity)
            }

            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func emptyToNil(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

#Preview {
    NavigationStack {
        OpportunityEditorView(onSaved: { _ in })
    }
    .appServices(MockAppServices.preview)
}
