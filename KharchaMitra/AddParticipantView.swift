
import SwiftUI

struct AddParticipantView: View {
    @State private var name: String = ""
    @State private var amountOwed: Double?
    var onAdd: (SharedParticipant) -> Void

    @Environment(\.dismiss) private var dismiss

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && amountOwed != nil && amountOwed! > 0
    }

    var body: some View {
        NavigationView {
            Form {
                TextField("Participant Name", text: $name)
                TextField("Amount Owed", value: $amountOwed, format: .currency(code: "INR"))
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("Add Participant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        if let amount = amountOwed {
                            let participant = SharedParticipant(name: name, amountOwed: amount)
                            onAdd(participant)
                            dismiss()
                        }
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
}
