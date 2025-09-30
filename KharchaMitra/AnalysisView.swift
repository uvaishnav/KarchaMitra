import SwiftUI

struct AnalysisView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var pdfURL: URL?
    @State private var showShareSheet = false

    var body: some View {
        NavigationView {
            TabView {
                AnalysisOverviewView()
                    .tabItem {
                        Label("Overview", systemImage: "chart.pie")
                    }

                AnalysisTrendsView()
                    .tabItem {
                        Label("Trends", systemImage: "chart.xyaxis.line")
                    }

                AnalysisCategoriesView()
                    .tabItem {
                        Label("Categories", systemImage: "list.bullet")
                    }

                AnalysisSharedView()
                    .tabItem {
                        Label("Shared", systemImage: "person.2")
                    }
            }
            .navigationTitle("Analysis")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export PDF", systemImage: "square.and.arrow.up") {
                        exportToPDF()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let pdfURL = pdfURL {
                    ShareSheet(activityItems: [pdfURL])
                }
            }
        }
    }
    
    @MainActor
    private func exportToPDF() {
        let pdfGenerator = PDFGenerator()
        
        if let url = pdfGenerator.generate(content: {
            VStack {
                AnalysisOverviewView(isForPDF: true)
                AnalysisTrendsView(isForPDF: true)
                AnalysisCategoriesView(isForPDF: true)
                AnalysisSharedView(isForPDF: true)
            }
            .environment(\.modelContext, modelContext)
        }) {
            self.pdfURL = url
            self.showShareSheet = true
        }
    }
}

#Preview {
    AnalysisView()
        .modelContainer(for: [Expense.self, Category.self, Settlement.self], inMemory: true)
}
