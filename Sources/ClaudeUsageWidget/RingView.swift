import SwiftUI

/// Donut ring with a percentage label in the center, styled after the
/// Stats app's RAM ring (colored arc for the used portion, gray track for
/// the rest).
struct RingView: View {
    let percent: Double // 0...1

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.25), lineWidth: 10)

            Circle()
                .trim(from: 0, to: max(0.001, percent))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.green, .yellow, .orange, .red]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Text("\(Int(percent * 100))%")
                .font(.system(size: 20, weight: .semibold))
        }
        .frame(width: 80, height: 80)
    }
}
