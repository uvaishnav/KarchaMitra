import SwiftUI

struct AnalysisView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var pdfURL: URL?
    @State private var showShareSheet = false
    @State private var isGeneratingPDF = false

    var body: some View {
        NavigationView {
            ZStack {
                // Modern Tab View with Custom Styling
                TabView {
                    AnalysisOverviewView()
                        .tabItem {
                            Label("Overview", systemImage: "chart.pie.fill")
                        }

                    AnalysisTrendsView()
                        .tabItem {
                            Label("Trends", systemImage: "chart.xyaxis.line")
                        }

                    AnalysisCategoriesView()
                        .tabItem {
                            Label("Categories", systemImage: "square.grid.2x2.fill")
                        }

                    AnalysisSharedView()
                        .tabItem {
                            Label("Shared", systemImage: "person.2.fill")
                        }
                }
                .tint(Color.brandMagenta)
                
                // Modern PDF Generation Overlay
                if isGeneratingPDF {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .transition(.opacity)
                    
                    VStack(spacing: AppSpacing.lg) {
                        // Animated Progress Indicator
                        ZStack {
                            Circle()
                                .stroke(Color.brandMagenta.opacity(0.2), lineWidth: 4)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .trim(from: 0, to: 0.7)
                                .stroke(
                                    Color.primaryGradient,
                                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                                )
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: isGeneratingPDF)
                        }
                        
                        VStack(spacing: AppSpacing.xs) {
                            Text("Generating PDF")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Compiling your financial analysis")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(AppSpacing.xl)
                    .background(
                        RoundedRectangle(cornerRadius: AppCornerRadius.xLarge)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppCornerRadius.xLarge)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .elevatedShadow()
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .navigationTitle("Financial Analysis")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: exportToPDF) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.richtext.fill")
                            Text("PDF")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(Color.primaryGradient)
                    }
                    .disabled(isGeneratingPDF)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let pdfURL = pdfURL {
                    ShareSheet(activityItems: [pdfURL])
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isGeneratingPDF)
        }
    }
    
    private func exportToPDF() {
        Task {
            await MainActor.run {
                withAnimation {
                    isGeneratingPDF = true
                }
            }
            
            defer {
                Task {
                    await MainActor.run {
                        withAnimation {
                            isGeneratingPDF = false
                        }
                    }
                }
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
