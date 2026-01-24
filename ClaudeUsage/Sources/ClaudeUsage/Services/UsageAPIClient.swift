import Foundation

actor UsageAPIClient {
    private let apiURL = URL(string: "https://api.anthropic.com/api/oauth/usage")!
    private var cache: UsageLimits?
    private var cacheTime: Date?
    private let cacheDuration: TimeInterval = 30

    func fetchUsage(forceRefresh: Bool = false) async -> UsageLimits? {
        // Check cache
        if !forceRefresh, let cache = cache, let cacheTime = cacheTime {
            if Date().timeIntervalSince(cacheTime) < cacheDuration {
                return cache
            }
        }

        guard let token = KeychainService.getOAuthToken() else {
            return cache
        }

        var request = URLRequest(url: apiURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return cache
            }

            let apiResponse = try JSONDecoder().decode(UsageAPIResponse.self, from: data)
            let limits = parseResponse(apiResponse)

            self.cache = limits
            self.cacheTime = Date()

            return limits
        } catch {
            return cache
        }
    }

    private func parseResponse(_ response: UsageAPIResponse) -> UsageLimits {
        UsageLimits(
            fiveHourUtilization: response.fiveHour?.utilization ?? 0,
            fiveHourResetsAt: parseResetTime(response.fiveHour?.resetsAt),
            sevenDayUtilization: response.sevenDay?.utilization ?? 0,
            sevenDayResetsAt: parseResetTime(response.sevenDay?.resetsAt),
            opusUtilization: response.sevenDayOpus?.utilization ?? 0,
            opusResetsAt: parseResetTime(response.sevenDayOpus?.resetsAt)
        )
    }

    private func parseResetTime(_ ts: String?) -> Date? {
        guard let ts = ts else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: ts) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: ts)
    }
}

// MARK: - API Response Models

private struct UsageAPIResponse: Codable {
    let fiveHour: UsagePeriod?
    let sevenDay: UsagePeriod?
    let sevenDayOpus: UsagePeriod?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case sevenDayOpus = "seven_day_opus"
    }
}

private struct UsagePeriod: Codable {
    let utilization: Double?
    let resetsAt: String?

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
    }
}
