import SwiftUI
import InterviewOSDomain

public struct CardView: View {
    public let card: ProcessCard

    public init(card: ProcessCard) {
        self.card = card
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(card.title)
                .font(.headline)
                .foregroundStyle(.primary)

            HStack(spacing: 8) {
                Text(card.kind.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.15))
                    .clipShape(Capsule())

                Text(card.status.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(Capsule())
            }

            if let scheduledAt = card.scheduledAt {
                Text(scheduledAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.thinMaterial)
        )
    }
}

public struct KanbanColumnView: View {
    public let stage: Stage
    public let cards: [ProcessCard]
    public let onAddCard: (Stage) -> Void
    public let onMoveCard: (UUID, UUID) -> Void
    public let onSelectCard: (ProcessCard) -> Void

    @State private var isDropTargeted = false

    public init(
        stage: Stage,
        cards: [ProcessCard],
        onAddCard: @escaping (Stage) -> Void,
        onMoveCard: @escaping (UUID, UUID) -> Void,
        onSelectCard: @escaping (ProcessCard) -> Void
    ) {
        self.stage = stage
        self.cards = cards
        self.onAddCard = onAddCard
        self.onMoveCard = onMoveCard
        self.onSelectCard = onSelectCard
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(stage.title)
                        .font(.headline)
                    Text("\(cards.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    onAddCard(stage)
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.plain)
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(cards) { card in
                        Button {
                            onSelectCard(card)
                        } label: {
                            CardView(card: card)
                        }
                        .buttonStyle(.plain)
                        .draggable(card.id.uuidString)
                    }
                }
            }
        }
        .padding(12)
        .frame(width: 290, alignment: .top)
        .frame(minHeight: 420, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isDropTargeted ? Color.blue.opacity(0.18) : Color.gray.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isDropTargeted ? Color.blue : Color.clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.2), value: isDropTargeted)
        .dropDestination(for: String.self) { items, _ in
            guard let first = items.first, let cardID = UUID(uuidString: first) else {
                return false
            }
            onMoveCard(cardID, stage.id)
            return true
        } isTargeted: { targeted in
            isDropTargeted = targeted
        }
    }
}

public struct KanbanBoardView: View {
    public let stages: [Stage]
    public let cardsByStage: [UUID: [ProcessCard]]
    public let onAddCard: (Stage) -> Void
    public let onMoveCard: (UUID, UUID) -> Void
    public let onSelectCard: (ProcessCard) -> Void

    public init(
        stages: [Stage],
        cardsByStage: [UUID: [ProcessCard]],
        onAddCard: @escaping (Stage) -> Void,
        onMoveCard: @escaping (UUID, UUID) -> Void,
        onSelectCard: @escaping (ProcessCard) -> Void
    ) {
        self.stages = stages
        self.cardsByStage = cardsByStage
        self.onAddCard = onAddCard
        self.onMoveCard = onMoveCard
        self.onSelectCard = onSelectCard
    }

    public var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 14) {
                ForEach(stages.sorted(by: { $0.order < $1.order })) { stage in
                    KanbanColumnView(
                        stage: stage,
                        cards: cardsByStage[stage.id, default: []],
                        onAddCard: onAddCard,
                        onMoveCard: onMoveCard,
                        onSelectCard: onSelectCard
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

#Preview("Card") {
    CardView(
        card: ProcessCard(
            opportunityId: UUID(),
            stageId: UUID(),
            title: "System Design Interview",
            kind: .systemDesign,
            status: .scheduled,
            scheduledAt: Date().addingTimeInterval(3600)
        )
    )
    .padding()
}

#Preview("Kanban Board") {
    let opportunityID = UUID()
    let stages = DomainTemplates.defaultStages(for: opportunityID)
    let cards = [
        ProcessCard(opportunityId: opportunityID, stageId: stages[0].id, title: "HR Screen", kind: .hr, status: .planned),
        ProcessCard(opportunityId: opportunityID, stageId: stages[2].id, title: "Coding Round", kind: .coding, status: .scheduled, scheduledAt: Date().addingTimeInterval(7200))
    ]

    return KanbanBoardView(
        stages: stages,
        cardsByStage: Dictionary(grouping: cards, by: \.stageId),
        onAddCard: { _ in },
        onMoveCard: { _, _ in },
        onSelectCard: { _ in }
    )
}
