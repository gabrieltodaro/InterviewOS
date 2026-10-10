import SwiftUI
import InterviewOSDomain
import InterviewOSPersistence

private struct OpportunityListItem: Identifiable {
    let opportunity: Opportunity
    let company: Company

    var id: UUID { opportunity.id }
}

public struct OpportunitiesListView: View {
    @Environment(\.appServices) private var services

    @State private var searchText = ""
    @State private var items: [OpportunityListItem] = []
    @State private var isShowingEditor = false
    @State private var editingItem: OpportunityListItem?
    @State private var errorMessage: String?

    public init() {}

    public var body: some View {
        List {
            ForEach(items) { item in
                NavigationLink {
                    OpportunityBoardView(
                        opportunity: item.opportunity,
                        company: item.company
                    )
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.opportunity.roleTitle)
                            .font(.headline)
                        Text(item.company.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .swipeActions {
                    Button("Edit") {
                        editingItem = item
                        isShowingEditor = true
                    }
                    .tint(.blue)
                }
            }
            .onDelete(perform: delete)
        }
        .listStyle(.plain)
        .navigationTitle("Opportunities")
        .searchable(text: $searchText, prompt: "Search company or role")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editingItem = nil
                    isShowingEditor = true
                } label: {
                    Label("Add Opportunity", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isShowingEditor) {
            NavigationStack {
                OpportunityEditorView(
                    existingOpportunity: editingItem?.opportunity,
                    existingCompany: editingItem?.company,
                    onSaved: { _ in
                        isShowingEditor = false
                        editingItem = nil
                        load()
                    }
                )
            }
        }
        .task(id: searchText) {
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

    private func delete(at offsets: IndexSet) {
        do {
            for index in offsets {
                try services.opportunities.delete(id: items[index].opportunity.id)
            }
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func load() {
        do {
            let opportunities = try services.opportunities.list(search: searchText)
            items = try opportunities.map { opportunity in
                let company = try services.opportunities.fetchCompany(id: opportunity.companyId)
                    ?? Company(id: opportunity.companyId, name: "Unknown Company")
                return OpportunityListItem(opportunity: opportunity, company: company)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        OpportunitiesListView()
    }
    .appServices(MockAppServices.preview)
}
