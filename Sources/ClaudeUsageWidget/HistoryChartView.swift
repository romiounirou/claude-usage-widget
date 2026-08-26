import SwiftUI

struct HistoryChartView: View {
    let days: [DayUsage]

    private var maxValue: Int {
        max(days.map(\.totalTokens).max() ?? 0, 1)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(days) { day in
                VStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(day.id == days.last?.id ? Color.accentColor : Color.accentColor.opacity(0.55))
                        .frame(height: max(2, CGFloat(day.totalTokens) / CGFloat(maxValue) * 70))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 70, alignment: .bottom)
    }
}
