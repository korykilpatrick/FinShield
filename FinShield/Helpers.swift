extension Int {
    var abbreviated: String {
        if self >= 1_000_000 {
            return String(format: "%.1fm", Double(self) / 1_000_000)
        } else if self >= 1000 {
            return String(format: "%.1fk", Double(self) / 1000)
        } else {
            return "\(self)"
        }
    }
}
