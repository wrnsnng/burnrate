import Foundation

struct SessionInfo: Identifiable {
    let id: String
    let slug: String
    let projectPath: String
    let encodedProject: String
    let timestamp: Date
    let messageCount: Int
    let totalTokens: Int
    let summary: String?
    let model: String

    var projectName: String {
        URL(fileURLWithPath: projectPath).lastPathComponent
    }
}

struct CurrentSession {
    let sessionId: String
    let slug: String
    let projectPath: String
    let startTime: Date
    let inputTokens: Int
    let outputTokens: Int
    let cacheReadTokens: Int
    let cacheCreationTokens: Int
    let messageCount: Int

    var totalTokens: Int {
        inputTokens + outputTokens
    }

    var projectName: String {
        URL(fileURLWithPath: projectPath).lastPathComponent
    }
}
