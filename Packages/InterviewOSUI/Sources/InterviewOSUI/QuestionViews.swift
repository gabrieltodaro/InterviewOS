import SwiftUI
import InterviewOSDomain
import InterviewOSPersistence

public struct TagChipsView: View {
    public let tags: [Tag]
    public let selectedTagNames: Set<String>
    public let onTap: (Tag) -> Void
    public let onRemove: ((Tag) -> Void)?

    public init(
        tags: [Tag],
        selectedTagNames: Set<String> = [],
        onTap: @escaping (Tag) -> Void,
        onRemove: ((Tag) -> Void)? = nil
    ) {
        self.tags = tags
        self.selectedTagNames = selectedTagNames
        self.onTap = onTap
        self.onRemove = onRemove
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags) { tag in
                    HStack(spacing: 6) {
                        Button {
                            onTap(tag)
                        } label: {
                            Text(tag.name)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    selectedTagNames.contains(tag.name) ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.15)
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        if let onRemove {
                            Button(role: .destructive) {
                                onRemove(tag)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

public struct QuestionBankView: View {
    @Environment(\.appServices) private var services

    @State private var searchText = ""
    @State private var selectedTags: Set<String> = []
    @State private var tags: [Tag] = []
    @State private var questions: [Question] = []
    @State private var editingQuestion: Question?
    @State private var showingNewQuestion = false
    @State private var errorMessage: String?

    public init() {}

    public var body: some View {
        List {
            if !tags.isEmpty {
                Section("Tags") {
                    TagChipsView(tags: tags, selectedTagNames: selectedTags) { tag in
                        toggle(tag: tag)
                    }
                }
            }

            Section("Questions") {
                ForEach(questions) { question in
                    Button {
                        editingQuestion = question
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(question.text)
                                .font(.headline)
                                .foregroundStyle(.primary)

                            HStack(spacing: 8) {
                                Text("Difficulty: \(question.difficulty)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                ForEach(question.tags) { tag in
                                    Text(tag.name)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Color.gray.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: delete)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Question Bank")
        .searchable(text: $searchText, prompt: "Search questions")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewQuestion = true
                } label: {
                    Label("New Question", systemImage: "plus")
                }
            }
        }
        .sheet(item: $editingQuestion) { question in
            NavigationStack {
                QuestionDetailView(question: question) {
                    load()
                    editingQuestion = nil
                }
            }
        }
        .sheet(isPresented: $showingNewQuestion) {
            NavigationStack {
                QuestionDetailView(question: nil) {
                    load()
                    showingNewQuestion = false
                }
            }
        }
        .task(id: searchText + selectedTags.sorted().joined(separator: ",")) {
            load()
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

    private func toggle(tag: Tag) {
        if selectedTags.contains(tag.name) {
            selectedTags.remove(tag.name)
        } else {
            selectedTags.insert(tag.name)
        }
    }

    private func delete(at offsets: IndexSet) {
        do {
            for index in offsets {
                try services.questions.delete(id: questions[index].id)
            }
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func load() {
        do {
            tags = try services.questions.allTags()
            questions = try services.questions.list(
                search: searchText,
                tagNames: Array(selectedTags)
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

public struct QuestionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appServices) private var services

    private let existingQuestion: Question?
    private let onSaved: () -> Void

    @State private var text: String
    @State private var notes: String
    @State private var difficulty: Double
    @State private var tags: [Tag]
    @State private var newTagName = ""
    @State private var errorMessage: String?

    public init(question: Question?, onSaved: @escaping () -> Void) {
        self.existingQuestion = question
        self.onSaved = onSaved

        _text = State(initialValue: question?.text ?? "")
        _notes = State(initialValue: question?.notes ?? "")
        _difficulty = State(initialValue: Double(question?.difficulty ?? 3))
        _tags = State(initialValue: question?.tags ?? [])
    }

    public var body: some View {
        Form {
            Section("Question") {
                TextEditor(text: $text)
                    .frame(minHeight: 140)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Difficulty: \(Int(difficulty))")
                    Slider(value: $difficulty, in: 1...5, step: 1)
                }
            }

            Section("Tags") {
                TagChipsView(tags: tags, onTap: { _ in }, onRemove: { tag in
                    tags.removeAll { $0.id == tag.id }
                })

                HStack {
                    TextField("Add tag", text: $newTagName)
                    Button("Add") {
                        let trimmed = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        if !tags.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                            tags.append(Tag(name: trimmed))
                        }
                        newTagName = ""
                    }
                }
            }

            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 120)
            }
        }
        .navigationTitle(existingQuestion == nil ? "New Question" : "Edit Question")
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
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
            let persistedTags = try tags.map { tag in
                try services.questions.upsertTag(named: tag.name)
            }

            if var question = existingQuestion {
                question.text = text
                question.notes = notes
                question.difficulty = Int(difficulty)
                question.tags = persistedTags
                question.updatedAt = Date()
                try services.questions.update(question)
            } else {
                let question = Question(
                    text: text,
                    tags: persistedTags,
                    difficulty: Int(difficulty),
                    notes: notes
                )
                try services.questions.create(question)
            }

            onSaved()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview("Question Bank") {
    NavigationStack {
        QuestionBankView()
    }
    .appServices(MockAppServices.preview)
}

#Preview("Question Detail") {
    NavigationStack {
        QuestionDetailView(question: Question(text: "How does ARC work in Swift?", tags: [Tag(name: "Swift")], difficulty: 3), onSaved: {})
    }
    .appServices(MockAppServices.preview)
}

#Preview("Tags") {
    TagChipsView(
        tags: [Tag(name: "Algorithms"), Tag(name: "System Design")],
        selectedTagNames: ["Algorithms"],
        onTap: { _ in },
        onRemove: nil
    )
    .padding()
}
