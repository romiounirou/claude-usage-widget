import SwiftUI

/// Semi-circle threshold gauge, styled after the Stats app's RAM gauge.
struct GaugeView: View {
    let percent: Double // 0...1

    private var statusLabel: String {
        switch percent {
        case ..<0.5: return "Tranquilo"
        case ..<0.8: return "Moderado"
        default: return "Alto"
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                ArcShape(startAngle: .degrees(180), endAngle: .degrees(360))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.green, .yellow, .orange, .red]),
                            center: .center,
                            startAngle: .degrees(180),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 100, height: 50)

                NeedleShape(percent: percent)
                    .stroke(Color.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 100, height: 50)
            }
            .frame(height: 54)

            Text(statusLabel)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

private struct ArcShape: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        let radius = min(rect.width, rect.height * 2) / 2
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        return path
    }
}

private struct NeedleShape: Shape {
    let percent: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        let radius = min(rect.width, rect.height * 2) / 2 - 4
        let angle = Angle.degrees(180 + 180 * min(max(percent, 0), 1))
        let end = CGPoint(
            x: center.x + radius * cos(angle.radians),
            y: center.y + radius * sin(angle.radians)
        )
        path.move(to: center)
        path.addLine(to: end)
        return path
    }
}
