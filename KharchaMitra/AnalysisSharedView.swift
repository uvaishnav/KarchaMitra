import SwiftUI
import SwiftData

struct ParticipantShareInfo: Identifiable {
    let id = UUID()
    let name: String
    let totalShared: Double
    let totalPaid: Double
    var netBalance: Double { totalShared - totalPaid }
}

struct AnalysisSharedView: View {
    @Query var expenses: [Expense]
    @Query var settlements: [Settlement]
    var isForPDF: Bool = false

    private var participantData: [ParticipantShareInfo] {
        let sharedExpenses = expenses.filter { $0.isShared }
        let allParticipants = sharedExpenses.flatMap { $0.sharedParticipants }

        let totalSharedByName = Dictionary(grouping: allParticipants, by: { $0.name })
            .mapValues { participants in
                participants.reduce(0) { $0 + $1.amountOwed }
            }

        let totalPaidByName = Dictionary(grouping: settlements, by: { $0.participantName })
            .mapValues { settlements in
                settlements.reduce(0) { $0 + $1.amount }
            }
        
        let allNames = Set(totalSharedByName.keys).union(Set(totalPaidByName.keys))
        
        return allNames.map { name in
            let totalShared = totalSharedByName[name] ?? 0
            let totalPaid = totalPaidByName[name] ?? 0
            return ParticipantShareInfo(name: name, totalShared: totalShared, totalPaid: totalPaid)
        }.sorted(by: { $0.name < $1.name })
    }
    
    private var totalLent: Double {
        participantData.reduce(0) { $0 + $1.totalShared }
    }
    
    private var totalRecovered: Double {
        participantData.reduce(0) { $0 + $1.totalPaid }
    }

    var body: some View {
        if isForPDF {
            content
        } else {
            ScrollView {
                content
            }
        }
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 24) {
            GroupBox("Overall Shared Finances") {
                HStack {
                    VStack {
                        Text("Total Lent")
                        Text(totalLent.toCurrency()).foregroundColor(.red)
                    }
                    Spacer()
                    VStack {
                        Text("Total Recovered")
                        Text(totalRecovered.toCurrency()).foregroundColor(.green)
                    }
                }
            }

            GroupBox("Balance by Person") {
                if participantData.isEmpty {
                    Text("No shared expenses yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(participantData) { participant in
                        HStack {
                            Text(participant.name)
                            Spacer()
                            if participant.netBalance > 0 {
                                Text("Owes you \(participant.netBalance.toCurrency())")
                                    .foregroundColor(.orange)
                            } else if participant.netBalance < 0 {
                                Text("Overpaid \((-participant.netBalance).toCurrency())")
                                    .foregroundColor(.green)
                            } else {
                                Text("Settled up")
                                    .foregroundColor(.secondary)
                            }
                        }
                        Divider()
                    }
                }
            }
        }
        .padding()
    }
}
