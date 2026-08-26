import Foundation

/// Approximate Anthropic API list prices (USD per million tokens).
/// Used only to show a rough cost estimate — not a billing source of truth.
enum PricingTable {
    private struct Rates {
        let input: Double
        let output: Double
        let cacheWrite: Double
        let cacheRead: Double
    }

    private static let rates: [(match: String, rates: Rates)] = [
        ("opus", Rates(input: 15.0, output: 75.0, cacheWrite: 18.75, cacheRead: 1.50)),
        ("sonnet", Rates(input: 3.0, output: 15.0, cacheWrite: 3.75, cacheRead: 0.30)),
        ("haiku", Rates(input: 0.80, output: 4.0, cacheWrite: 1.0, cacheRead: 0.08)),
    ]

    private static func rates(for model: String) -> Rates {
        let lower = model.lowercased()
        for entry in rates where lower.contains(entry.match) {
            return entry.rates
        }
        // Default to Sonnet-tier pricing when the model is unrecognized.
        return rates.first(where: { $0.match == "sonnet" })!.rates
    }

    static func cost(model: String, input: Int, output: Int, cacheRead: Int, cacheCreation: Int) -> Double {
        let r = rates(for: model)
        let million = 1_000_000.0
        return (Double(input) / million) * r.input
            + (Double(output) / million) * r.output
            + (Double(cacheRead) / million) * r.cacheRead
            + (Double(cacheCreation) / million) * r.cacheWrite
    }

    static func contextLimit(model: String) -> Int {
        let lower = model.lowercased()
        if lower.contains("[1m]") || lower.contains("1m-context") {
            return 1_000_000
        }
        return 200_000
    }
}
