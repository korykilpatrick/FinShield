import Foundation

extension String {
    func removeTrailingZeroDecimal() -> String {
        let pattern = "^(\\d+)\\.0([A-Za-z]*)$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return self }
        let range = NSRange(startIndex..., in: self)
        if let match = regex.firstMatch(in: self, range: range),
           let intRange = Range(match.range(at: 1), in: self),
           let suffixRange = Range(match.range(at: 2), in: self) {
            return String(self[intRange]) + String(self[suffixRange])
        }
        return self
    }
}

extension Int {
    var abbreviated: String {
        let num = Double(self)
        switch num {
        case 1_000_000...:
            let formatted = String(format: "%.1fM", num / 1_000_000)
            return formatted.removeTrailingZeroDecimal()
        case 1_000...:
            let formatted = String(format: "%.1fk", num / 1_000)
            return formatted.removeTrailingZeroDecimal()
        default:
            return "\(self)"
        }
    }
}
