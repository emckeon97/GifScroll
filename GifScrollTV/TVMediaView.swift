import SwiftUI
import AVKit
import ImageIO

/// Renders one feed item's media on tvOS: still image, animated GIF,
/// or looping video. tvOS has no WebKit, so GIFs are decoded with
/// ImageIO and animated frame-by-frame.
struct TVMediaView: View {
    let item: FeedItem

    var body: some View {
        switch item.kind {
        case .video:
            TVLoopingVideoView(url: item.url)
        case .gif:
            TVAnimatedGifView(url: item.url)
        case .image:
            AsyncImage(url: item.url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure:
                    Color(white: 0.08)
                case .empty:
                    ProgressView().tint(.white)
                @unknown default:
                    Color(white: 0.08)
                }
            }
        }
    }
}

/// Animated GIF on tvOS via ImageIO frame decoding. Downloads the GIF,
/// extracts frames + per-frame delays, and advances on a timer.
struct TVAnimatedGifView: View {
    let url: URL
    @StateObject private var animator = TVGifAnimator()

    var body: some View {
        Group {
            if let image = animator.currentImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView().tint(.white)
            }
        }
        .onAppear { animator.load(url: url) }
        .onDisappear { animator.stop() }
    }
}

@MainActor
final class TVGifAnimator: ObservableObject {
    @Published var currentImage: UIImage?
    private var frames: [UIImage] = []
    private var totalDuration: TimeInterval = 0
    private var timer: Timer?
    private var task: Task<Void, Never>?

    func load(url: URL) {
        stop()
        task = Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return }
                let count = CGImageSourceGetCount(source)
                guard count > 0 else { return }
                var images: [UIImage] = []
                var duration: TimeInterval = 0
                for i in 0..<count {
                    guard let cg = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
                    images.append(UIImage(cgImage: cg))
                    duration += Self.delay(for: source, index: i)
                }
                guard !images.isEmpty else { return }
                // Single-frame "GIF" (or still): show it, no timer needed.
                if images.count == 1 {
                    self.currentImage = images[0]
                    return
                }
                self.frames = images
                // Guard against zero-duration metadata: floor at 0.1s/frame.
                self.totalDuration = max(duration, Double(images.count) * 0.1)
                self.currentImage = images[0]
                self.startTimer(frameCount: images.count)
            } catch {
                // Leave the placeholder spinner; a retry happens on reappear.
            }
        }
    }

    private func startTimer(frameCount: Int) {
        let interval = totalDuration / Double(frameCount)
        var index = 0
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                index = (index + 1) % frameCount
                self.currentImage = self.frames[index]
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        task?.cancel()
        task = nil
        frames = []
        currentImage = nil
    }

    private static func delay(for source: CGImageSource, index: Int) -> TimeInterval {
        guard let props = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
              let gif = props[kCGImagePropertyGIFDictionary] as? [CFString: Any] else {
            return 0.1
        }
        let unclamped = gif[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval ?? 0
        let clamped = gif[kCGImagePropertyGIFDelayTime] as? TimeInterval ?? 0
        let delay = unclamped > 0 ? unclamped : clamped
        // Browsers treat delays under ~20ms as 100ms; match that.
        return delay < 0.02 ? 0.1 : delay
    }

    deinit {
        timer?.invalidate()
        task?.cancel()
    }
}

/// Looping video player for tvOS. A small observable model owns the
/// AVPlayer and the end-of-playback observer so the video loops until
/// the view disappears.
struct TVLoopingVideoView: View {
    let url: URL
    @StateObject private var model = TVVideoModel()

    var body: some View {
        Group {
            if let player = model.player {
                VideoPlayer(player: player)
            } else {
                ProgressView().tint(.white)
            }
        }
        .onAppear { model.play(url: url) }
        .onDisappear { model.pause() }
    }
}

@MainActor
final class TVVideoModel: ObservableObject {
    @Published var player: AVPlayer?
    private var endObserver: NSObjectProtocol?

    func play(url: URL) {
        if player == nil {
            let p = AVPlayer(url: url)
            player = p
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: p.currentItem,
                queue: .main
            ) { [weak p] _ in
                p?.seek(to: .zero)
                p?.play()
            }
        }
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    deinit {
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
