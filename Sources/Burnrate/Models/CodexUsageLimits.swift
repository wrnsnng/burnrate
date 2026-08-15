import Foundation

struct CodexUsageLimits {
    let fiveHourUtilization: Double
    let fiveHourResetsAt: Date?
    let weeklyUtilization: Double
    let weeklyResetsAt: Date?

    // Token counts from current session
    let inputTokens: Int?
    let outputTokens: Int?
    let reasoningTokens: Int?

    static let empty = CodexUsageLimits(
        fiveHourUtilization: 0,
        fiveHourResetsAt: nil,
        weeklyUtilization: 0,
        weeklyResetsAt: nil,
        inputTokens: nil,
        outputTokens: nil,
        reasoningTokens: nil
    )
}
