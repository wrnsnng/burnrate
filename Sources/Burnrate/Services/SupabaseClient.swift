import Foundation

actor SupabaseClient {
    private let projectURL = "https://jhftgrxvvjysyclhpvnz.supabase.co"
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpoZnRncnh2dmp5c3ljbGhwdm56Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA1OTA0NzcsImV4cCI6MjA4NjE2NjQ3N30.zD7jB7fnSMQTzfM4_e5w5Jwr1R9xhpoorDuAxnNClrI"

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    /// Upsert all provider usage data to Supabase
    func pushUsage(userId: String, providers: [String: ProviderUsage]) async {
        let rows = providers.map { (providerId, usage) in
            UsageRow(
                userId: userId,
                provider: providerId,
                primaryUtilization: usage.primaryUtilization,
                primaryLabel: usage.primaryLabel,
                primaryResetsAt: usage.primaryResetsAt,
                secondaryUtilization: usage.secondaryUtilization,
                secondaryLabel: usage.secondaryLabel,
                secondaryResetsAt: usage.secondaryResetsAt,
                extraInfo: usage.extraInfo,
                recordedAt: Date()
            )
        }

        guard !rows.isEmpty else { return }

        guard let url = URL(string: "\(projectURL)/rest/v1/usage_snapshots") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        // Upsert on (user_id, provider) conflict
        request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        // RLS: pass user_id for row-level security
        request.setValue(userId, forHTTPHeaderField: "x-burnrate-user-id")
        request.timeoutInterval = 10

        do {
            request.httpBody = try encoder.encode(rows)
            let (_, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse, http.statusCode >= 200 && http.statusCode < 300 {
                NSLog("[Supabase] Pushed \(rows.count) provider(s)")
            } else if let http = response as? HTTPURLResponse {
                NSLog("[Supabase] Push failed with status \(http.statusCode)")
            }
        } catch {
            NSLog("[Supabase] Push error: \(error.localizedDescription)")
        }
    }

    /// Fetch latest usage data for a user (used by iOS widget)
    func fetchUsage(userId: String) async -> [String: ProviderUsage] {
        guard let url = URL(string: "\(projectURL)/rest/v1/usage_snapshots?user_id=eq.\(userId)&select=*") else {
            return [:]
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(userId, forHTTPHeaderField: "x-burnrate-user-id")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return [:]
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            let rows = try decoder.decode([UsageRow].self, from: data)

            var result: [String: ProviderUsage] = [:]
            for row in rows {
                result[row.provider] = ProviderUsage(
                    primaryUtilization: row.primaryUtilization,
                    primaryLabel: row.primaryLabel,
                    primaryResetsAt: row.primaryResetsAt,
                    secondaryUtilization: row.secondaryUtilization,
                    secondaryLabel: row.secondaryLabel,
                    secondaryResetsAt: row.secondaryResetsAt,
                    extraInfo: row.extraInfo
                )
            }
            return result
        } catch {
            NSLog("[Supabase] Fetch error: \(error.localizedDescription)")
            return [:]
        }
    }
}

// MARK: - Row Model

private struct UsageRow: Codable {
    let userId: String
    let provider: String
    let primaryUtilization: Double
    let primaryLabel: String
    let primaryResetsAt: Date?
    let secondaryUtilization: Double?
    let secondaryLabel: String?
    let secondaryResetsAt: Date?
    let extraInfo: [String: String]?
    let recordedAt: Date
}
