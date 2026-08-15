import WidgetKit
import Foundation

// MARK: - Supabase Configuration

private enum SupabaseConfig {
    static let url = "https://jhftgrxvvjysyclhpvnz.supabase.co"
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpoZnRncnh2dmp5c3ljbGhwdm56Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA1OTA0NzcsImV4cCI6MjA4NjE2NjQ3N30.zD7jB7fnSMQTzfM4_e5w5Jwr1R9xhpoorDuAxnNClrI"
    static let table = "usage_snapshots"
}

private enum CacheKeys {
    static let cachedProviders = "cachedProviders"
    static let cachedDate = "cachedDate"
}

// MARK: - Supabase Row

/// Matches the columns of the `usage_snapshots` table.
private struct UsageSnapshotRow: Decodable {
    let user_id: String
    let provider: String
    let primary_utilization: Double
    let primary_label: String
    let primary_resets_at: String?
    let secondary_utilization: Double?
    let secondary_label: String?
    let secondary_resets_at: String?
    let extra_info: [String: String]?
    let recorded_at: String?
}

// MARK: - Timeline Provider

struct UsageTimelineProvider: TimelineProvider {

    private let appGroup = "group.com.commontools.burnrate"

    // MARK: Placeholder

    func placeholder(in context: Context) -> UsageEntry {
        .placeholder
    }

    // MARK: Snapshot

    func getSnapshot(in context: Context, completion: @escaping (UsageEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }
        // Try cached data first for a fast snapshot, then fall back to placeholder.
        if let cached = loadCachedEntry() {
            completion(cached)
        } else {
            completion(.placeholder)
        }
    }

    // MARK: Timeline

    func getTimeline(in context: Context, completion: @escaping (Timeline<UsageEntry>) -> Void) {
        guard let userId = userID() else {
            // No user ID available -- show empty state and retry in 15 minutes.
            let entry = UsageEntry.empty
            let next = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
            completion(Timeline(entries: [entry], policy: .after(next)))
            return
        }

        fetchFromSupabase(userId: userId) { providers in
            let now = Date()
            let entry: UsageEntry

            if let providers = providers, !providers.isEmpty {
                entry = UsageEntry(
                    date: now,
                    providers: providers.sorted { $0.name < $1.name },
                    lastUpdated: now,
                    isPlaceholder: false
                )
                cacheEntry(entry)
            } else if let cached = loadCachedEntry() {
                // Network failed -- use cached data.
                entry = UsageEntry(
                    date: now,
                    providers: cached.providers,
                    lastUpdated: cached.lastUpdated,
                    isPlaceholder: false
                )
            } else {
                entry = UsageEntry.empty
            }

            // Refresh at the earliest reset time, or in 15 minutes.
            let earliestReset = entry.providers
                .compactMap { $0.primaryResetsAt }
                .filter { $0 > now }
                .min()

            let nextRefresh = earliestReset ?? Calendar.current.date(byAdding: .minute, value: 15, to: now)!

            completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
        }
    }

    // MARK: - Networking

    private func fetchFromSupabase(userId: String, completion: @escaping ([ProviderData]?) -> Void) {
        let encodedUserId = userId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? userId
        let endpoint = "\(SupabaseConfig.url)/rest/v1/\(SupabaseConfig.table)?user_id=eq.\(encodedUserId)&select=*"

        guard let url = URL(string: endpoint) else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(userId, forHTTPHeaderField: "x-burnrate-user-id")
        request.timeoutInterval = 15

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }

            let decoder = JSONDecoder()
            guard let rows = try? decoder.decode([UsageSnapshotRow].self, from: data) else {
                completion(nil)
                return
            }

            let iso8601 = ISO8601DateFormatter()
            iso8601.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            let fallbackFormatter = ISO8601DateFormatter()
            fallbackFormatter.formatOptions = [.withInternetDateTime]

            func parseDate(_ string: String?) -> Date? {
                guard let s = string else { return nil }
                return iso8601.date(from: s) ?? fallbackFormatter.date(from: s)
            }

            let providers = rows.map { row in
                ProviderData(
                    id: row.provider,
                    name: ProviderData.displayName(for: row.provider),
                    primaryUtilization: row.primary_utilization,
                    primaryLabel: row.primary_label,
                    primaryResetsAt: parseDate(row.primary_resets_at),
                    secondaryUtilization: row.secondary_utilization,
                    secondaryLabel: row.secondary_label,
                    secondaryResetsAt: parseDate(row.secondary_resets_at)
                )
            }

            completion(providers)
        }.resume()
    }

    // MARK: - User ID

    private func userID() -> String? {
        // iCloud key-value store synced from the macOS app.
        NSUbiquitousKeyValueStore.default.string(forKey: "supabaseUserId")
    }

    // MARK: - Caching

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroup)
    }

    private func cacheEntry(_ entry: UsageEntry) {
        guard let defaults = sharedDefaults else { return }
        if let data = try? JSONEncoder().encode(entry.providers) {
            defaults.set(data, forKey: CacheKeys.cachedProviders)
            defaults.set(entry.lastUpdated ?? Date(), forKey: CacheKeys.cachedDate)
        }
    }

    private func loadCachedEntry() -> UsageEntry? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: CacheKeys.cachedProviders),
              let providers = try? JSONDecoder().decode([ProviderData].self, from: data)
        else {
            return nil
        }

        let cachedDate = defaults.object(forKey: CacheKeys.cachedDate) as? Date
        return UsageEntry(
            date: .now,
            providers: providers,
            lastUpdated: cachedDate,
            isPlaceholder: false
        )
    }
}
