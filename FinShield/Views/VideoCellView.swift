import SwiftUI
import AVKit

struct VideoCellView: View {
    let video: Video
    @State private var player: AVPlayer?
    @State private var playerError: Error?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .onAppear {
                        player.play()
                        player.automaticallyWaitsToMinimizeStalling = true
                    }
                    .onDisappear { player.pause() }
            } else if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            if let error = playerError {
                VStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                        .font(.largeTitle)
                    Text("Error loading video")
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(12)
            }
        }
        .onAppear { setupPlayer() }
        .onDisappear { cleanupPlayer() }
    }

    private func setupPlayer() {
        isLoading = true
        let asset = AVURLAsset(url: video.videoURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        asset.loadValuesAsynchronously(forKeys: ["playable"]) {
            DispatchQueue.main.async {
                var error: NSError?
                let status = asset.statusOfValue(forKey: "playable", error: &error)
                switch status {
                case .loaded:
                    let playerItem = AVPlayerItem(asset: asset)
                    playerItem.preferredForwardBufferDuration = 2.0
                    let newPlayer = AVPlayer(playerItem: playerItem)
                    newPlayer.actionAtItemEnd = .none

                    NotificationCenter.default.addObserver(
                        forName: .AVPlayerItemFailedToPlayToEndTime,
                        object: playerItem,
                        queue: .main
                    ) { notification in
                        if let err = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
                            self.playerError = err
                        }
                    }

                    NotificationCenter.default.addObserver(
                        forName: .AVPlayerItemDidPlayToEndTime,
                        object: playerItem,
                        queue: .main
                    ) { _ in
                        newPlayer.seek(to: .zero)
                        newPlayer.play()
                    }

                    self.player = newPlayer
                    self.isLoading = false

                case .failed:
                    self.playerError = error ?? NSError(domain: "", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: "Failed to load video"
                    ])
                    self.isLoading = false

                default:
                    self.playerError = NSError(domain: "", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: "Unknown error loading video"
                    ])
                    self.isLoading = false
                }
            }
        }
    }

    private func cleanupPlayer() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        NotificationCenter.default.removeObserver(self)
        player = nil
        isLoading = false
    }
}

