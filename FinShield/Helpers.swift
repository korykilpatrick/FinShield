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

// New: parseSRTTime utility
func parseSRTTime(_ timeString: String) -> TimeInterval {
    // Format: HH:MM:SS,mmm => e.g. "00:01:10,500"
    let parts = timeString.split(separator: ":") // ["00","01","10,500"]
    guard parts.count == 3 else { return 0 }
    let hours = Double(parts[0]) ?? 0
    let minutes = Double(parts[1]) ?? 0
    let secMillis = parts[2].split(separator: ",")
    let secs = Double(secMillis.first ?? "0") ?? 0
    let millis = Double(secMillis.last ?? "0") ?? 0
    return hours * 3600 + minutes * 60 + secs + (millis / 1000.0)
}