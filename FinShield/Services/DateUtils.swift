import Foundation

struct DateUtils {
    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    static func formattedDate(from date: Date) -> String {
        return displayFormatter.string(from: date)
    }
}
