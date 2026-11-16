import Foundation

enum AuthCountdown {
    static let duration: TimeInterval = 300

    static func deadline(from now: Date = Date()) -> Date {
        now.addingTimeInterval(duration)
    }

    static func remainingSeconds(until deadline: Date, now: Date = Date()) -> Int {
        max(0, Int(deadline.timeIntervalSince(now).rounded(.up)))
    }
}
