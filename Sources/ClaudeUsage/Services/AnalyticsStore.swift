import Foundation

struct UsageSnapshot: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let fiveHourUtilization: Double
    let sevenDayUtilization: Double
    let opusUtilization: Double

    init(timestamp: Date = Date(), fiveHour: Double, sevenDay: Double, opus: Double = 0) {
        self.id = UUID()
        self.timestamp = timestamp
        self.fiveHourUtilization = fiveHour
        self.sevenDayUtilization = sevenDay
        self.opusUtilization = opus
    }
}

struct DailyStats: Codable {
    var totalTokens: Int
    var sessionCount: Int
    var estimatedCost: Double

    static let empty = DailyStats(totalTokens: 0, sessionCount: 0, estimatedCost: 0)
}

struct AnalyticsData: Codable {
    var snapshots: [UsageSnapshot]
    var dailyStats: [String: DailyStats] // Key: "YYYY-MM-DD"

    static let empty = AnalyticsData(snapshots: [], dailyStats: [:])
}

actor AnalyticsStore {
    private let storageURL: URL
    private var data: AnalyticsData
    private var lastSnapshotTime: Date?

    private let snapshotInterval: TimeInterval = 3600 // 1 hour
    private let maxSnapshotAge: TimeInterval = 30 * 24 * 3600 // 30 days
    private let maxDailyStatsAge: TimeInterval = 365 * 24 * 3600 // 1 year

    init() {
        let claudeUsageDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude-usage")

        // Create directory if needed
        try? FileManager.default.createDirectory(at: claudeUsageDir, withIntermediateDirectories: true)

        self.storageURL = claudeUsageDir.appendingPathComponent("analytics.json")
        self.data = AnalyticsStore.loadData(from: storageURL)

        NSLog("[Analytics] Loaded \(data.snapshots.count) snapshots, \(data.dailyStats.count) daily stats")
    }

    private static func loadData(from url: URL) -> AnalyticsData {
        guard FileManager.default.fileExists(atPath: url.path),
              let jsonData = try? Data(contentsOf: url),
              let data = try? JSONDecoder().decode(AnalyticsData.self, from: jsonData) else {
            return .empty
        }
        return data
    }

    func recordSnapshot(fiveHour: Double, sevenDay: Double, opus: Double) {
        let now = Date()

        // Only record if enough time has passed
        if let lastTime = lastSnapshotTime,
           now.timeIntervalSince(lastTime) < snapshotInterval {
            return
        }

        let snapshot = UsageSnapshot(timestamp: now, fiveHour: fiveHour, sevenDay: sevenDay, opus: opus)
        data.snapshots.append(snapshot)
        lastSnapshotTime = now

        // Cleanup old snapshots
        let cutoff = now.addingTimeInterval(-maxSnapshotAge)
        data.snapshots.removeAll { $0.timestamp < cutoff }

        save()
        NSLog("[Analytics] Recorded snapshot: 5h=\(Int(fiveHour))%, 7d=\(Int(sevenDay))%")
    }

    func recordDailyStats(tokens: Int, sessions: Int) {
        let dateKey = dateKey(for: Date())

        var stats = data.dailyStats[dateKey] ?? .empty
        stats.totalTokens = tokens
        stats.sessionCount = sessions
        // Rough cost estimate: ~$3 per 1M tokens (blended rate)
        stats.estimatedCost = Double(tokens) / 1_000_000 * 3.0

        data.dailyStats[dateKey] = stats

        // Cleanup old daily stats
        let cutoffDate = Date().addingTimeInterval(-maxDailyStatsAge)
        let minDateKey = self.dateKey(for: cutoffDate)
        data.dailyStats = data.dailyStats.filter { $0.key >= minDateKey }

        save()
    }

    func getSnapshots(last hours: Int) -> [UsageSnapshot] {
        let cutoff = Date().addingTimeInterval(-Double(hours) * 3600)
        return data.snapshots.filter { $0.timestamp >= cutoff }.sorted { $0.timestamp < $1.timestamp }
    }

    func getTodayStats() -> DailyStats {
        return data.dailyStats[dateKey(for: Date())] ?? .empty
    }

    func getWeekStats() -> (tokens: Int, sessions: Int, cost: Double) {
        let calendar = Calendar.current
        var totalTokens = 0
        var totalSessions = 0
        var totalCost = 0.0

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let key = dateKey(for: date)
            if let stats = data.dailyStats[key] {
                totalTokens += stats.totalTokens
                totalSessions += stats.sessionCount
                totalCost += stats.estimatedCost
            }
        }

        return (totalTokens, totalSessions, totalCost)
    }

    func getAllSnapshots() -> [UsageSnapshot] {
        return data.snapshots.sorted { $0.timestamp < $1.timestamp }
    }

    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func save() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(data)
            try jsonData.write(to: storageURL)
        } catch {
            NSLog("[Analytics] Failed to save: \(error)")
        }
    }
}
