import SwiftUI

struct AnalysisView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var pdfURL: URL?
    @State private var showShareSheet = false
    @State private var isGeneratingPDF = false

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
                    .disabled(isGeneratingPDF)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let pdfURL = pdfURL {
                    ShareSheet(activityItems: [pdfURL])
                }
            }
        }
        .overlay {
            if isGeneratingPDF {
                Color.black.opacity(0.4).ignoresSafeArea()
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Generating PDF...")
                        .font(.headline)
                }
                .padding(30)
                .background(.regularMaterial)
                .cornerRadius(15)
                .shadow(radius: 10)
            }
        }
    }
    
    private func exportToPDF() {
        Task {
            await MainActor.run { isGeneratingPDF = true }
            
            defer {
                Task { await MainActor.run { isGeneratingPDF = false } }
            }

            let pdfGenerator = PDFGenerator()
            
            if let url = await pdfGenerator.generate(content: {
                VStack {
                    AnalysisOverviewView(isForPDF: true)
                    AnalysisTrendsView(isForPDF: true)
                    AnalysisCategoriesView(isForPDF: true)
                    AnalysisSharedView(isForPDF: true)
                }
                .environment(\.modelContext, modelContext)
            }) {
                await MainActor.run {
                    self.pdfURL = url
                    self.showShareSheet = true
                }
            }
        }
    }
}

#Preview {
    AnalysisView()
        .modelContainer(for: [Expense.self, Category.self, Settlement.self], inMemory: true)
}