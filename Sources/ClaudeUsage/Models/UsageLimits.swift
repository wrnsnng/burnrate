import Foundation

struct UsageLimits {
    let fiveHourUtilization: Double
    let fiveHourResetsAt: Date?
    let sevenDayUtilization: Double
    let sevenDayResetsAt: Date?
    let opusUtilization: Double
    let opusResetsAt: Date?

    static let empty = UsageLimits(
        fiveHourUtilization: 0,
        fiveHourResetsAt: nil,
        sevenDayUtilization: 0,
        sevenDayResetsAt: nil,
        opusUtilization: 0,
        opusResetsAt: nil
    )
}
