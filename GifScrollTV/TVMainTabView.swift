import SwiftUI

/// tvOS root: tab bar with Feed + Account. Upload stays on iPhone —
/// tvOS has no photo picker.
struct TVMainTabView: View {
    @EnvironmentObject var likeManager: LikeManager
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab = 0 // Feed is the landing tab.

    var body: some View {
        TabView(selection: $selectedTab) {
            TVFeedView()
                .tabItem {
                    Label("Feed", systemImage: "flame")
                }
                .tag(0)

            TVAccountView()
                .tabItem {
                    Label("Account", systemImage: "person")
                }
                .tag(1)
        }
        .environmentObject(likeManager)
        .environmentObject(authManager)
    }
}
