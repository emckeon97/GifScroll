import SwiftUI

/// tvOS entry point for GifScroll.
///
/// Lean-back 10-foot UI: focus navigation via the Siri Remote, no swipe
/// gestures. Tab bar with Feed + Account — uploading stays on iPhone
/// (tvOS has no photo picker).
@main
struct GifScrollTVApp: App {
    @StateObject private var likeManager = LikeManager()
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            TVMainTabView()
                .environmentObject(likeManager)
                .environmentObject(authManager)
        }
    }
}
