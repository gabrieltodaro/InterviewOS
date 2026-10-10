import SwiftUI
import InterviewOSDomain

private struct EditableStage: Identifiable {
    var id: UUID
    var title: String
    var isClosedColumn: Bool
}

public struct StageEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appServices) private var services

    private let opportunityId: UUID
    private let existingStageIDs: Set<UUID>
    private let onSaved: () -> Void

    @State private var stages: [EditableStage]
    @State private var deletedStageIDs: Set<UUID> = []
    @State private var errorMessage: String?

    public init(opportunityId: UUID, stages: [Stage], onSaved: @escaping () -> Void) {
        self.opportunityId = opportunityId
        self.existingStageIDs = Set(stages.map(\.id))
        self.onSaved = onSaved
        _stages = State(initialValue: stages.sorted(by: { $0.order < $1.order }).map {
            EditableStage(id: $0.id, title: $0.title, isClosedColumn: $0.isClosedColumn)
        })
    }

    public var body: some View {
        List {
            ForEach($stages) { $stage in
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Stage Title", text: $stage.title)
                    Toggle("Closed Column", isOn: $stage.isClosedColumn)
                        .font(.footnote)
                }
                .padding(.vertical, 4)
            }
            .onDelete(perform: delete)
            .onMove(perform: move)

            Button {
                stages.append(EditableStage(id: UUID(), title: "New Stage", isClosedColumn: false))
            } label: {
                Label("Add Stage", systemImage: "plus")
            }
        }
        .navigationTitle("Edit Stages")
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .automatic) {
                EditButton()
            }
            #endif
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(stages.isEmpty || stages.contains(where: { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }))
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

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let id = stages[index].id
            if existingStageIDs.contains(id) {
                deletedStageIDs.insert(id)
            }
        }
        stages.remove(atOffsets: offsets)
    }

    private func move(from source: IndexSet, to destination: Int) {
        stages.move(fromOffsets: source, toOffset: destination)
    }

    private func save() {
        do {
            for stageID in deletedStageIDs {
                try services.stages.delete(id: stageID)
            }

            for (index, stage) in stages.enumerated() {
                let domainStage = Stage(
                    id: stage.id,
                    opportunityId: opportunityId,
                    title: stage.title,
                    order: index,
                    isClosedColumn: stage.isClosedColumn
                )

                if existingStageIDs.contains(stage.id) {
                    try services.stages.update(domainStage)
                } else {
                    try services.stages.create(domainStage)
                }
            }

            try services.stages.reorder(
                opportunityId: opportunityId,
                orderedStageIds: stages.map(\.id)
            )

            onSaved()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        StageEditorView(
            opportunityId: UUID(),
            stages: [
                Stage(opportunityId: UUID(), title: "Applied", order: 0),
                Stage(opportunityId: UUID(), title: "Interviewing", order: 1)
            ],
            onSaved: {}
        )
    }
    .appServices(MockAppServices.preview)
}
