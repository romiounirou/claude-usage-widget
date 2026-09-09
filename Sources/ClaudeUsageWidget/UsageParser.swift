import Foundation

/// Incrementally scans `~/.claude/projects/**/*.jsonl` session logs and
/// aggregates token usage per day. Only newly-appended bytes are re-read
/// on each `refresh()`, so repeated polling stays cheap.
final class UsageParser {
    private var fileCursors: [String: UInt64] = [:]

    private var dailyInput: [String: Int] = [:]
    private var dailyOutput: [String: Int] = [:]
    private var dailyCacheRead: [String: Int] = [:]
    private var dailyCacheCreation: [String: Int] = [:]
    private var dailyCost: [String: Double] = [:]

    private var latestTimestamp: Date = .distantPast
    private var latestContextTokens: Int = 0
    private var latestModel: String = ""

    private let projectsDir: URL

    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f
    }()

    private let labelFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d/M"
        f.timeZone = .current
        return f
    }()

    private let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    init() {
        projectsDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude", isDirectory: true)
            .appendingPathComponent("projects", isDirectory: true)
    }

    func refresh() {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: projectsDir,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        for case let url as URL in enumerator {
            guard url.pathExtension == "jsonl" else { continue }
            processFile(url)
        }
    }

    private func processFile(_ url: URL) {
        let path = url.path
        guard let handle = try? FileHandle(forReadingFrom: url) else { return }
        defer { try? handle.close() }

        let fileSize = (try? handle.seekToEnd()) ?? 0
        let startOffset = fileCursors[path] ?? 0

        if fileSize < startOffset {
            // File was rotated/truncated; start over.
            fileCursors[path] = 0
            processFile(url)
            return
        }
        guard fileSize > startOffset else { return }

        try? handle.seek(toOffset: startOffset)
        let data = handle.readDataToEndOfFile()
        fileCursors[path] = fileSize

        guard let text = String(data: data, encoding: .utf8) else { return }
        text.enumerateLines { [weak self] line, _ in
            self?.processLine(line)
        }
    }

    private func processLine(_ line: String) {
        guard !line.isEmpty, let lineData = line.data(using: .utf8) else { return }
        guard let obj = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else { return }
        guard let message = obj["message"] as? [String: Any],
              let usage = message["usage"] as? [String: Any],
              let timestampStr = obj["timestamp"] as? String,
              let date = isoFormatter.date(from: timestampStr) else { return }

        let inputTokens = (usage["input_tokens"] as? Int) ?? 0
        let outputTokens = (usage["output_tokens"] as? Int) ?? 0
        let cacheRead = (usage["cache_read_input_tokens"] as? Int) ?? 0
        let cacheCreation = (usage["cache_creation_input_tokens"] as? Int) ?? 0
        let model = (message["model"] as? String) ?? "unknown"

        let dayKey = dayFormatter.string(from: date)
        dailyInput[dayKey, default: 0] += inputTokens
        dailyOutput[dayKey, default: 0] += outputTokens
        dailyCacheRead[dayKey, default: 0] += cacheRead
        dailyCacheCreation[dayKey, default: 0] += cacheCreation
        dailyCost[dayKey, default: 0] += PricingTable.cost(
            model: model, input: inputTokens, output: outputTokens,
            cacheRead: cacheRead, cacheCreation: cacheCreation
        )

        if date >= latestTimestamp {
            latestTimestamp = date
            latestContextTokens = inputTokens + cacheRead + cacheCreation
            latestModel = model
        }
    }

    func snapshot() -> UsageSnapshot {
        var snap = UsageSnapshot()
        let today = Date()
        let todayKey = dayFormatter.string(from: today)

        var days: [DayUsage] = []
        for offset in stride(from: 13, through: 0, by: -1) {
            guard let day = Calendar.current.date(byAdding: .day, value: -offset, to: today) else { continue }
            let key = dayFormatter.string(from: day)
            // "Fresh" tokens only (input + output + cache-write) — cache-read
            // is excluded here too, for the same reason as todayFreshTokens.
            let fresh = (dailyInput[key] ?? 0) + (dailyOutput[key] ?? 0) + (dailyCacheCreation[key] ?? 0)
            days.append(DayUsage(dayKey: key, label: labelFormatter.string(from: day), totalTokens: fresh))
        }

        snap.contextUsedTokens = latestContextTokens
        snap.contextLimitTokens = PricingTable.contextLimit(model: latestModel)
        snap.contextModel = latestModel
        snap.todayInputTokens = dailyInput[todayKey] ?? 0
        snap.todayOutputTokens = dailyOutput[todayKey] ?? 0
        snap.todayCacheReadTokens = dailyCacheRead[todayKey] ?? 0
        snap.todayCacheCreationTokens = dailyCacheCreation[todayKey] ?? 0
        snap.estimatedCostToday = dailyCost[todayKey] ?? 0
        snap.last14Days = days
        snap.lastUpdated = Date()
        return snap
    }
}
