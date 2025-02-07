import SwiftUI

struct VideoScrubberView: View {
    @Binding var currentTime: Double
    @Binding var totalDuration: Double
    var onScrub: (Double) -> Void

    @GestureState private var isPressing = false
    @State private var isExpanded = false
    @EnvironmentObject var scrubbingManager: ScrubbingManager

    var body: some View {
        let normalizedValue = totalDuration > 0 ? currentTime / totalDuration : 0

        GeometryReader { geometry in
            let trackWidth = geometry.size.width
            let sliderPosition = normalizedValue * trackWidth

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 4)
                Rectangle()
                    .fill(Color.green)
                    .frame(width: sliderPosition, height: 4)
                Circle()
                    .fill(Color.green)
                    .frame(width: isExpanded ? 24 : 12, height: isExpanded ? 24 : 12)
                    .offset(x: sliderPosition - (isExpanded ? 12 : 6))
                    .shadow(radius: isExpanded ? 5 : 0)
            }
            .frame(height: isExpanded ? 40 : 20)
            .contentShape(Rectangle()) // ensure the whole width is hittable
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
