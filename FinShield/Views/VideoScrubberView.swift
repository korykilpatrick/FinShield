import SwiftUI

struct VideoScrubberView: View {
    @Binding var currentTime: Double
    @Binding var totalDuration: Double
    var onScrub: (Double) -> Void
    var factCheckResults: [FactCheckResult] // New parameter

    @GestureState private var isPressing = false
    @State private var isExpanded = false
    @EnvironmentObject var scrubbingManager: ScrubbingManager

    var body: some View {
        let normalizedValue = totalDuration > 0 ? currentTime / totalDuration : 0

        GeometryReader { geometry in
            let trackWidth = geometry.size.width
            let sliderPosition = normalizedValue * trackWidth

            ZStack(alignment: .leading) {
                // Background scrubber track
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 4)
                
                // Fact-check markers: one notch per fact-check result
                if totalDuration > 0 {
                    ForEach(factCheckResults, id: \.id) { fc in
                        let normalizedPosition = fc.endTime / totalDuration
                        if normalizedPosition >= 0 && normalizedPosition <= 1 {
                            Rectangle()
                                .fill(Color.yellow)
                                .frame(width: 2, height: 8)
                                .offset(x: normalizedPosition * trackWidth - 1, y: -10)
                        }
                    }
                }
                
                // Filled portion of the track
                Rectangle()
                    .fill(Color.white)
                    .frame(width: sliderPosition, height: 4)
                
                // Slider thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: isExpanded ? 24 : 12, height: isExpanded ? 24 : 12)
                    .offset(x: sliderPosition - (isExpanded ? 12 : 6))
                    .shadow(radius: isExpanded ? 5 : 0)
            }
            .frame(height: isExpanded ? 40 : 20)
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let location = drag.location.x
                        let ratio = max(0, min(1, location / trackWidth))
                        onScrub(ratio * totalDuration)
                        withAnimation {
                            isExpanded = true
                            scrubbingManager.isScrubbing = true
                        }
                    }
                    .onEnded { _ in
                        withAnimation {
                            isExpanded = false
                            scrubbingManager.isScrubbing = false
                        }
                    }
            )
        }
        .frame(height: 40)
    }
}