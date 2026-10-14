import SwiftUI

/// Minimal report sheet for tvOS. Reports land in the `reports` table
/// for review in the Supabase dashboard.
struct TVReportView: View {
    let gifID: String

    @Environment(\.dismiss) var dismiss

    @State private var reason = "Spam"
    @State private var isSending = false
    @State private var submitted = false

    private let reasons = [
        "Spam", "Harassment", "Hate speech", "Sexual content", "Violence", "Other",
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if submitted {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    Text("Thanks — we'll take a look.")
                        .foregroundColor(.white)
                    Spacer()
                } else {
                    Picker("Reason", selection: $reason) {
                        ForEach(reasons, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.menu)

                    Button("Submit Report") { submit() }
                        .disabled(isSending)

                    Spacer()
                }
            }
            .padding(48)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Report")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func submit() {
        isSending = true
        Task {
            do {
                try await SupabaseManager.shared.insertReport(
                    gifID: gifID,
                    reason: reason,
                    details: "",
                    reporterName: "anon"
                )
                submitted = true
            } catch {
                // Keep the sheet open so they can retry.
            }
            isSending = false
        }
    }
}
