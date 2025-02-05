import Foundation

/// Utility for formatting dates consistently throughout the app.
struct DateUtils {
    /// A shared date formatter configured to display dates in medium style (e.g., "Nov 20, 2024").
    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    /// Returns a formatted string for a given date.
    ///
    /// - Parameter date: The date to format.
    /// - Returns: A string representation of the date.
    static func formattedDate(from date: Date) -> String {
        return displayFormatter.string(from: date)
    }
}
