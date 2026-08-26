import Foundation

enum TokenFormat {
    static func short(_ value: Int) -> String {
        let v = Double(value)
        switch v {
        case 1_000_000...:
            return String(format: "%.1fM", v / 1_000_000)
        case 1_000...:
            return String(format: "%.1fK", v / 1_000)
        default:
            return "\(value)"
        }
    }

    static func cost(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}
