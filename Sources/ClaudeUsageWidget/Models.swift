import Foundation

struct DayUsage: Identifiable {
    let id: String
    let label: String
    let totalTokens: Int

    init(dayKey: String, label: String, totalTokens: Int) {
        self.id = dayKey
        self.label = label
        self.totalTokens = totalTokens
    }
}

struct UsageSnapshot {
    var contextUsedTokens: Int = 0
    var contextLimitTokens: Int = 200_000
    var contextModel: String = ""

    var todayInputTokens: Int = 0
    var todayOutputTokens: Int = 0
    var todayCacheReadTokens: Int = 0
    var todayCacheCreationTokens: Int = 0
    var todayTotalTokens: Int = 0
    var estimatedCostToday: Double = 0

    var last14Days: [DayUsage] = []
    var lastUpdated: Date = Date(timeIntervalSince1970: 0)

    var contextPercent: Double {
        guard contextLimitTokens > 0 else { return 0 }
        return min(1.0, Double(contextUsedTokens) / Double(contextLimitTokens))
    }
}
