import SwiftUI

/// Lean-back meme feed for tvOS: a focusable card grid navigated with the
/// Siri Remote. Selecting a card opens the detail view.
struct TVFeedView: View {
    @StateObject private var reddit = RedditService()
    @EnvironmentObject var likeManager: LikeManager

    private let columns = [
        GridItem(.flexible(), spacing: 32),
        GridItem(.flexible(), spacing: 32),
        GridItem(.flexible(), spacing: 32),
        GridItem(.flexible(), spacing: 32),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if reddit.isLoading && reddit.items.isEmpty {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                } else if let error = reddit.errorMessage, reddit.items.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        Text(error)
                            .foregroundColor(.white)
                        Button("Try Again") { reddit.memeFeed() }
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 32) {
                            ForEach(reddit.items) { item in
                                NavigationLink {
                                    TVDetailView(item: item)
                                } label: {
                                    TVCardView(item: item)
                                }
                                .buttonStyle(.card)
                            }
                        }
                        .padding(48)
                    }
                }
            }
            .navigationTitle("GifScroll")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        reddit.memeFeed()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                reddit.likeManager = likeManager
                if reddit.items.isEmpty {
                    reddit.memeFeed()
                }
            }
        }
    }
}

/// One focusable meme card in the TV grid.
struct TVCardView: View {
    let item: FeedItem
    @EnvironmentObject var likeManager: LikeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: item.url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Color(white: 0.12)
                case .empty:
                    Color(white: 0.12)
                @unknown default:
                    Color(white: 0.12)
                }
            }
            .frame(height: 220)
            .clipped()
            .cornerRadius(12)

            Text(item.title)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                Image(
                    systemName: likeManager.isLiked(id: item.id)
                        ? "face.smiling.fill" : "face.smiling"
                )
                .foregroundColor(
                    likeManager.isLiked(id: item.id) ? .yellow : .gray
                )
                if item.kind == .video {
                    Image(systemName: "play.circle")
                        .foregroundColor(.gray)
                } else if item.kind == .gif {
                    Image(systemName: "gif")
                        .foregroundColor(.gray)
                }
            }
            .font(.caption)
        }
        .padding(12)
    }
}
