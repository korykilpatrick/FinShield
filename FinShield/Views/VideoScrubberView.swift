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
            .gesture(
                LongPressGesture(minimumDuration: 0.15)
                    .updating($isPressing) { current, state, _ in state = current }
                    .onEnded { _ in
                        withAnimation {
                            isExpanded = true
                            scrubbingManager.isScrubbing = true
                        }
                    }
                    .sequenced(before: DragGesture(minimumDistance: 0))
                    .onChanged { value in
                        switch value {
                        case .first(true):
                            break
                        case .second(true, let drag?):
                            let location = drag.location.x
                            let ratio = max(0, min(1, location / trackWidth))
                            let newTime = ratio * totalDuration
                            onScrub(newTime)
                        default:
                            break
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
