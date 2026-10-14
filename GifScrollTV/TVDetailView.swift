import SwiftUI

// MARK: - tvOS compatibility (file-local so this view builds in any target)
extension View {
    /// navigationBarTitleDisplayMode is unavailable on tvOS; no-op there.
    @ViewBuilder
    fileprivate func compatNavBarMode(_ mode: NavigationBarItem.TitleDisplayMode) -> some View {
        #if os(tvOS)
        self
        #else
        self.navigationBarTitleDisplayMode(mode)
        #endif
    }
}

/// Detail screen for one meme on tvOS: the media on the left, title and
/// focusable actions (laugh, comments, report) on the right.
struct TVDetailView: View {
    let item: FeedItem

    @EnvironmentObject var likeManager: LikeManager
    @State private var showingComments = false
    @State private var showingReport = false

    var body: some View {
        HStack(spacing: 48) {
            TVMediaView(item: item)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)

            VStack(alignment: .leading, spacing: 28) {
                Text(item.title)
                    .font(.title2)
                    .foregroundColor(.white)
                    .lineLimit(5)

                Button {
                    likeManager.toggleLike(id: item.id, title: item.title)
                } label: {
                    Label(
                        likeManager.isLiked(id: item.id) ? "Laughed!" : "Laugh",
                        systemImage: likeManager.isLiked(id: item.id)
                            ? "face.smiling.fill" : "face.smiling"
                    )
                    .font(.title3)
                }

                Button {
                    showingComments = true
                } label: {
                    Label("Comments", systemImage: "bubble.left")
                        .font(.title3)
                }

                Button(role: .destructive) {
                    showingReport = true
                } label: {
                    Label("Report", systemImage: "flag")
                        .font(.title3)
                }

                Spacer()
            }
            .frame(width: 420)
            .padding(48)
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Meme")
        .compatNavBarMode(.inline)
        .sheet(isPresented: $showingComments) {
            TVCommentsView(gifID: item.id)
        }
        .sheet(isPresented: $showingReport) {
            TVReportView(gifID: item.id)
        }
    }
}
