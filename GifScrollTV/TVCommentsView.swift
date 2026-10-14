import SwiftUI

/// Comment thread for a meme on tvOS, presented as a sheet.
/// TV comments post anonymously — there is no sign-in UI on TV;
/// signing in stays on iPhone.
struct TVCommentsView: View {
    let gifID: String

    @Environment(\.dismiss) var dismiss

    @State private var comments: [Comment] = []
    @State private var draft = ""
    @State private var isLoading = true
    @State private var isSending = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                } else if comments.isEmpty {
                    Spacer()
                    Text("No comments yet.")
                        .foregroundColor(.gray)
                    Text("Start the conversation.")
                        .foregroundColor(.gray)
                        .font(.caption)
                    Spacer()
                } else {
                    List(comments) { comment in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(comment.displayName)
                                .font(.caption)
                                .bold()
                                .foregroundColor(.gray)
                            Text(comment.body)
                                .foregroundColor(.white)
                        }
                        .listRowBackground(Color(white: 0.08))
                    }
                    .listStyle(.plain)
                }

                HStack(spacing: 16) {
                    TextField("Add a comment…", text: $draft)

                    Button("Send") { send() }
                        .disabled(
                            isSending
                                || draft.trimmingCharacters(
                                    in: .whitespacesAndNewlines
                                ).isEmpty
                        )
                }
                .padding(24)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Comments")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task { await load() }
        }
    }

    private func load() async {
        do {
            comments = try await SupabaseManager.shared.fetchComments(
                gifID: gifID
            )
        } catch {
            comments = []
        }
        isLoading = false
    }

    private func send() {
        let body = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        isSending = true
        Task {
            do {
                let comment = try await SupabaseManager.shared.insertComment(
                    gifID: gifID,
                    body: body,
                    displayName: "anon"
                )
                comments.append(comment)
                draft = ""
            } catch {
                // Leave the draft in place so nothing is lost.
            }
            isSending = false
        }
    }
}
