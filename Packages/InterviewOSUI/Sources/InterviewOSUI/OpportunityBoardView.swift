import SwiftUI
import InterviewOSDomain
import InterviewOSPersistence

public struct OpportunityBoardView: View {
    @Environment(\.appServices) private var services

    public let opportunity: Opportunity
    public let company: Company

    @State private var stages: [Stage] = []
    @State private var cards: [ProcessCard] = []
    @State private var selectedCard: ProcessCard?
    @State private var isShowingStageEditor = false
    @State private var errorMessage: String?

    public init(opportunity: Opportunity, company: Company) {
        self.opportunity = opportunity
        self.company = company
    }

    public var body: some View {
        VStack(spacing: 0) {
            KanbanBoardView(
                stages: stages,
                cardsByStage: Dictionary(grouping: cards, by: \.stageId),
                onAddCard: addCard,
                onMoveCard: moveCard,
                onSelectCard: { card in
                    selectedCard = card
                }
            )
        }
        .navigationTitle(opportunity.roleTitle)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Stages") {
                    isShowingStageEditor = true
                }
            }
        }
        .sheet(isPresented: $isShowingStageEditor) {
            NavigationStack {
                StageEditorView(
                    opportunityId: opportunity.id,
                    stages: stages,
                    onSaved: load
                )
            }
        }
        .sheet(item: $selectedCard) { card in
            NavigationStack {
                CardDetailView(
                    cardID: card.id,
                    opportunity: opportunity,
                    company: company,
                    onSaved: {
                        load()
                    }
                )
            }
        }
        .task {
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

    private func load() {
        do {
            stages = try services.stages.list(opportunityId: opportunity.id)
            cards = try services.cards.list(opportunityId: opportunity.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func addCard(to stage: Stage) {
        do {
            let card = ProcessCard(
                opportunityId: opportunity.id,
                stageId: stage.id,
                title: "New Process Event",
                kind: .generic,
                status: .planned
            )
            try services.cards.create(card)
            load()
            selectedCard = card
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func moveCard(_ cardId: UUID, _ stageId: UUID) {
        do {
            try services.cards.move(cardId: cardId, to: stageId)
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    let services = MockAppServices.preview
    let opportunity = (try? services.opportunities.list(search: nil).first) ?? Opportunity(companyId: UUID(), roleTitle: "iOS Engineer", jobDescription: "JD")
    let company = (try? services.opportunities.fetchCompany(id: opportunity.companyId)) ?? Company(id: opportunity.companyId, name: "Acme")

    return NavigationStack {
        OpportunityBoardView(opportunity: opportunity, company: company)
    }
    .appServices(services)
}
