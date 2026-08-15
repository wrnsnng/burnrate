import WidgetKit
import SwiftUI

// MARK: - Widget Configuration

struct BurnrateMainWidget: Widget {
    let kind: String = "BurnrateUsageWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UsageTimelineProvider()) { entry in
            BurnrateWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Burnrate Usage")
        .description("Track your LLM usage limits.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Bundle

@main
struct BurnrateWidgetBundle: WidgetBundle {
    var body: some Widget {
        BurnrateMainWidget()
    }
}
