//
//  ContentView.swift
//  Burnrate
//
//  Created by Marc Obieglo on 9/2/2026.
//

import SwiftUI
import WidgetKit

// MARK: - Supabase Config

private enum SupabaseConfig {
    static let url = "https://jhftgrxvvjysyclhpvnz.supabase.co"
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpoZnRncnh2dmp5c3ljbGhwdm56Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA1OTA0NzcsImV4cCI6MjA4NjE2NjQ3N30.zD7jB7fnSMQTzfM4_e5w5Jwr1R9xhpoorDuAxnNClrI"
    static let table = "usage_snapshots"
}

// MARK: - Theme

private enum Theme {
    // Brand
    static let accentGradient = LinearGradient(
        colors: [Color(hex: 0xF97316), Color(hex: 0xEA580C)],
        startPoint: .leading, endPoint: .trailing
    )

    // Status colors
    static let statusGreen  = Color(hex: 0x22C55E)
    static let statusOrange = Color(hex: 0xF97316)
    static let statusRed    = Color(hex: 0xEF4444)

    // Provider brand colors
    static func providerColor(_ id: String) -> Color {
        switch id.lowercased() {
        case "claude": return Color(hex: 0xDA7756)
        case "codex":  return Color(hex: 0x10A37F)
        case "kimi":   return Color(hex: 0x6366F1)
        case "gemini": return Color(hex: 0x4285F4)
        default:       return Color(hex: 0x3B82F6)
        }
    }

    // Progress bar gradient
    static func progressGradient(for value: Double) -> LinearGradient {
        if value >= 90 {
            return LinearGradient(colors: [Color(hex: 0xEF4444), Color(hex: 0xDC2626)],
                                  startPoint: .leading, endPoint: .trailing)
        } else if value >= 70 {
            return LinearGradient(colors: [Color(hex: 0xF97316), Color(hex: 0xEA580C)],
                                  startPoint: .leading, endPoint: .trailing)
        }
        return LinearGradient(colors: [Color(hex: 0x3B82F6), Color(hex: 0x2563EB)],
                              startPoint: .leading, endPoint: .trailing)
    }

    static func statusColor(for value: Double) -> Color {
        if value >= 90 { return statusRed }
        if value >= 70 { return statusOrange }
        return statusGreen
    }

    // Spacing
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 12
    static let spacingLG: CGFloat = 16

    // Radii
    static let radiusSM: CGFloat = 8
    static let radiusMD: CGFloat = 12
    static let radiusLG: CGFloat = 16
}

// MARK: - Color Extension

extension Color {
    fileprivate init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Data Models

private struct UsageSnapshotRow: Decodable {
    let provider: String
    let primary_utilization: Double
    let primary_label: String
    let primary_resets_at: String?
    let secondary_utilization: Double?
    let secondary_label: String?
    let secondary_resets_at: String?
}

private struct ProviderUsage: Identifiable {
    let id: String
    let name: String
    let primaryUtilization: Double
    let primaryLabel: String
    let primaryResetsAt: Date?
    let secondaryUtilization: Double?
    let secondaryLabel: String?
    let secondaryResetsAt: Date?

    static func displayName(for providerId: String) -> String {
        switch providerId.lowercased() {
        case "claude": return "Claude"
        case "codex": return "Codex"
        case "kimi": return "Kimi K2.5"
        case "gemini": return "Gemini"
        default: return providerId.capitalized
        }
    }

    static func sfIconName(for providerId: String) -> String {
        switch providerId.lowercased() {
        case "claude": return "brain.head.profile"
        case "codex":  return "chevron.left.forwardslash.chevron.right"
        case "kimi":   return "sparkles"
        case "gemini": return "diamond.fill"
        default:       return "cpu"
        }
    }
}

// MARK: - Fetch Helper

private func fetchProviders(userId: String) async -> [ProviderUsage] {
    let encodedUserId = userId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? userId
    let endpoint = "\(SupabaseConfig.url)/rest/v1/\(SupabaseConfig.table)?user_id=eq.\(encodedUserId)&select=*"

    guard let url = URL(string: endpoint) else { return [] }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
    request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue(userId, forHTTPHeaderField: "x-burnrate-user-id")
    request.timeoutInterval = 15

    do {
        let (data, _) = try await URLSession.shared.data(for: request)
        let rows = try JSONDecoder().decode([UsageSnapshotRow].self, from: data)

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallback = ISO8601DateFormatter()
        fallback.formatOptions = [.withInternetDateTime]

        func parseDate(_ s: String?) -> Date? {
            guard let s else { return nil }
            return iso.date(from: s) ?? fallback.date(from: s)
        }

        return rows.map { row in
            ProviderUsage(
                id: row.provider,
                name: ProviderUsage.displayName(for: row.provider),
                primaryUtilization: row.primary_utilization,
                primaryLabel: row.primary_label,
                primaryResetsAt: parseDate(row.primary_resets_at),
                secondaryUtilization: row.secondary_utilization,
                secondaryLabel: row.secondary_label,
                secondaryResetsAt: parseDate(row.secondary_resets_at)
            )
        }.sorted { $0.primaryUtilization > $1.primaryUtilization }
    } catch {
        NSLog("[Burnrate] Fetch error: \(error)")
        return []
    }
}

private func loadUserId() -> String? {
    let shared = UserDefaults(suiteName: "group.com.commontools.burnrate")
    if let iCloudId = NSUbiquitousKeyValueStore.default.string(forKey: "supabaseUserId"),
       !iCloudId.isEmpty {
        return iCloudId
    }
    if let sharedId = shared?.string(forKey: "supabaseUserId"),
       !sharedId.isEmpty {
        return sharedId
    }
    if let localId = UserDefaults.standard.string(forKey: "supabaseUserId"),
       !localId.isEmpty {
        return localId
    }
    return nil
}

private func saveUserId(_ id: String) {
    UserDefaults.standard.set(id, forKey: "supabaseUserId")
    UserDefaults(suiteName: "group.com.commontools.burnrate")?.set(id, forKey: "supabaseUserId")
    NSUbiquitousKeyValueStore.default.set(id, forKey: "supabaseUserId")
    NSUbiquitousKeyValueStore.default.synchronize()
    WidgetCenter.shared.reloadAllTimelines()
}

// MARK: - Content View (Diagnostic)

struct ContentView: View {
    @State private var lines: [String] = ["View created"]

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.system(size: 13, design: .monospaced))
                }
            }
            .navigationTitle("Burnrate Debug")
        }
        .task {
            log("task started")

            // Step 1: check userId
            let userId = loadUserId()
            log("userId: \(userId ?? "nil")")

            guard let userId, !userId.isEmpty else {
                log("NO userId — stopping")
                return
            }

            // Step 2: build request
            let encodedId = userId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? userId
            let endpoint = "\(SupabaseConfig.url)/rest/v1/\(SupabaseConfig.table)?user_id=eq.\(encodedId)&select=*"
            guard let url = URL(string: endpoint) else {
                log("BAD URL")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue(userId, forHTTPHeaderField: "x-burnrate-user-id")
            request.timeoutInterval = 15

            log("fetching...")

            // Step 3: fetch
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                log("HTTP \(status), \(data.count) bytes")

                // Step 4: decode
                let rows = try JSONDecoder().decode([UsageSnapshotRow].self, from: data)
                log("decoded \(rows.count) rows")

                for row in rows {
                    log("  \(row.provider): \(row.primary_utilization)% \(row.primary_label)")
                }

                log("DONE ✓")
            } catch {
                log("ERROR: \(error)")
            }
        }
    }

    private func log(_ msg: String) {
        NSLog("[Burnrate] %@", msg)
        lines.append(msg)
    }
}

// MARK: - Setup View

private struct SetupView: View {
    @Binding var showingManualEntry: Bool
    @Binding var manualIdText: String
    let onSave: (String) -> Void

    @State private var flameOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // Animated flame logo
            ZStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(Theme.accentGradient)
                    .blur(radius: 12)
                    .opacity(0.4)

                Image(systemName: "flame.fill")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(Theme.accentGradient)
                    .offset(y: flameOffset)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    flameOffset = -3
                }
            }

            VStack(spacing: 6) {
                Text("Burnrate")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("Track your LLM usage limits")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Steps card
            VStack(alignment: .leading, spacing: 16) {
                StepRow(number: 1, text: "Open Burnrate on your Mac")
                StepRow(number: 2, text: "Go to Settings → Sync")
                StepRow(number: 3, text: "Enable cloud sync")
                StepRow(number: 4, text: "Device ID syncs via iCloud")
            }
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: Theme.radiusMD)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radiusMD)
                            .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 4)

            Button {
                showingManualEntry = true
            } label: {
                Text("Enter Device ID Manually")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: 0xF97316))
            }

            Spacer()

            HStack(spacing: 6) {
                ProgressView()
                    .scaleEffect(0.7)
                Text("Waiting for iCloud sync…")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 24)
        .alert("Enter Device ID", isPresented: $showingManualEntry) {
            TextField("Paste your Device ID", text: $manualIdText)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            Button("Save") {
                let trimmed = manualIdText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { onSave(trimmed) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Copy your Device ID from Burnrate macOS (Settings → Sync).")
        }
    }
}

private struct StepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(
                    Circle().fill(
                        LinearGradient(
                            colors: [Color(hex: 0xF97316), Color(hex: 0xEA580C)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                )

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.primary)
        }
    }
}


// MARK: - Provider Card

private struct ProviderCard: View {
    let provider: ProviderUsage

    private var brandColor: Color {
        Theme.providerColor(provider.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingMD) {
            // Header
            HStack(spacing: Theme.spacingSM) {
                // Provider icon
                BrandIcon.shapeView(for: provider.id, size: 15)
                    .foregroundStyle(brandColor)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(brandColor.opacity(0.12))
                    )

                Text(provider.name)
                    .font(.system(size: 16, weight: .semibold))

                Spacer()

                // Status dot
                Circle()
                    .fill(Theme.statusColor(for: provider.primaryUtilization))
                    .frame(width: 8, height: 8)
            }

            // Primary bar
            AnimatedUsageBar(
                label: provider.primaryLabel,
                utilization: provider.primaryUtilization,
                resetsAt: provider.primaryResetsAt
            )

            // Secondary bar
            if let secUtil = provider.secondaryUtilization,
               let secLabel = provider.secondaryLabel {
                AnimatedUsageBar(
                    label: secLabel,
                    utilization: secUtil,
                    resetsAt: provider.secondaryResetsAt
                )
            }
        }
        .padding(Theme.spacingLG)
        .background {
            RoundedRectangle(cornerRadius: Theme.radiusMD)
                .fill(Color.primary.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusMD)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                )
        }
    }
}

// MARK: - Animated Usage Bar

private struct AnimatedUsageBar: View {
    let label: String
    let utilization: Double
    let resetsAt: Date?

    @State private var animatedValue: Double = 0

    private var percentage: Int { Int(utilization.rounded()) }

    private var isResetPending: Bool {
        guard let resetsAt = resetsAt else { return false }
        return resetsAt.timeIntervalSinceNow <= 0
    }

    private var shouldPulse: Bool {
        utilization >= 80 && !isResetPending
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingXS) {
            // Label row
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Text(isResetPending ? "\(percentage)% (prev)" : "\(percentage)%")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(
                        isResetPending ? Color.secondary.opacity(0.5) :
                        utilization >= 90 ? Theme.statusRed :
                        utilization >= 70 ? Theme.statusOrange :
                        Color.primary
                    )
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary.opacity(0.08))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.progressGradient(for: utilization))
                        .frame(width: max(0, geo.size.width * min(animatedValue, 100) / 100))
                        .opacity(isResetPending ? 0.45 : 1.0)
                        .shadow(
                            color: shouldPulse ? Theme.statusColor(for: utilization).opacity(0.4) : .clear,
                            radius: shouldPulse ? 4 : 0
                        )
                }
            }
            .frame(height: 7)

            // Reset timer
            if let resetsAt = resetsAt {
                if isResetPending {
                    Text("Previous cycle")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary)
                } else {
                    HStack(spacing: Theme.spacingXS) {
                        Text("Resets \(formatTimeRemaining(resetsAt))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.tertiary)

                        Text("(\(formatLocalTime(resetsAt)))")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                }
            }
        }
        .padding(Theme.spacingMD)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusSM)
                .fill(Color.primary.opacity(0.02))
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                animatedValue = utilization
            }
        }
        .onChange(of: utilization) { _, newValue in
            withAnimation(.easeOut(duration: 0.3)) {
                animatedValue = newValue
            }
        }
    }

    private func formatTimeRemaining(_ date: Date) -> String {
        let remaining = date.timeIntervalSince(.now)
        if remaining <= 0 { return "now" }
        let days = Int(remaining / 86400)
        let hours = Int(remaining.truncatingRemainder(dividingBy: 86400) / 3600)
        let minutes = Int(remaining.truncatingRemainder(dividingBy: 3600) / 60)
        if days > 0 { return "in \(days)d \(hours)h" }
        if hours > 0 { return "in \(hours)h \(minutes)m" }
        return "in \(minutes)m"
    }

    private func formatLocalTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
        } else if calendar.isDateInTomorrow(date) {
            formatter.dateFormat = "'Tomorrow' h:mm a"
        } else {
            formatter.dateFormat = "EEE h:mm a"
        }
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview("Dashboard") {
    ContentView()
}
