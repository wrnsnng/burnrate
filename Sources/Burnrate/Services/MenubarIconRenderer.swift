import AppKit

enum MenubarIconRenderer {
    static func render(
        fiveHour: Double,
        sevenDay: Double,
        colorScheme: MenubarColorScheme
    ) -> NSImage {
        let size = NSSize(width: 20, height: 20)
        let image = NSImage(size: size, flipped: false) { rect in
            // Layout constants
            let padding: CGFloat = 3
            let barHeight: CGFloat = 5
            let gap: CGFloat = 3
            let cornerRadius: CGFloat = 1.5

            let barWidth = rect.width - (padding * 2)
            let contentHeight = (barHeight * 2) + gap
            let startY = (rect.height - contentHeight) / 2

            // Background track color (subtle gray for unfilled portion)
            let trackColor = NSColor.white.withAlphaComponent(0.2)

            // Top bar (5-hour)
            let topBarY = startY + barHeight + gap
            let topBarRect = NSRect(x: padding, y: topBarY, width: barWidth, height: barHeight)
            let topFillWidth = barWidth * CGFloat(min(fiveHour, 100) / 100)
            let topFillRect = NSRect(x: padding, y: topBarY, width: topFillWidth, height: barHeight)

            // Bottom bar (7-day)
            let bottomBarY = startY
            let bottomBarRect = NSRect(x: padding, y: bottomBarY, width: barWidth, height: barHeight)
            let bottomFillWidth = barWidth * CGFloat(min(sevenDay, 100) / 100)
            let bottomFillRect = NSRect(x: padding, y: bottomBarY, width: bottomFillWidth, height: barHeight)

            // Draw track backgrounds
            let topTrackPath = NSBezierPath(roundedRect: topBarRect, xRadius: cornerRadius, yRadius: cornerRadius)
            trackColor.setFill()
            topTrackPath.fill()

            let bottomTrackPath = NSBezierPath(roundedRect: bottomBarRect, xRadius: cornerRadius, yRadius: cornerRadius)
            trackColor.setFill()
            bottomTrackPath.fill()

            // Get colors based on scheme
            let (topColor, bottomColor) = barColors(
                fiveHour: fiveHour,
                sevenDay: sevenDay,
                colorScheme: colorScheme
            )

            // Draw filled portions
            if topFillWidth > 0 {
                let topFillPath = NSBezierPath(roundedRect: topFillRect, xRadius: cornerRadius, yRadius: cornerRadius)
                topColor.setFill()
                topFillPath.fill()
            }

            if bottomFillWidth > 0 {
                let bottomFillPath = NSBezierPath(roundedRect: bottomFillRect, xRadius: cornerRadius, yRadius: cornerRadius)
                bottomColor.setFill()
                bottomFillPath.fill()
            }

            return true
        }

        image.isTemplate = false
        return image
    }

    private static func barColors(
        fiveHour: Double,
        sevenDay: Double,
        colorScheme: MenubarColorScheme
    ) -> (top: NSColor, bottom: NSColor) {
        switch colorScheme {
        case .dynamic:
            return (dynamicColor(for: fiveHour), dynamicColor(for: sevenDay))
        case .distinct:
            // Blue for 5-hour, purple for 7-day
            return (NSColor(hex: 0x3B82F6), NSColor(hex: 0xA855F7))
        case .monochrome:
            return (NSColor.white, NSColor.white)
        }
    }

    private static func dynamicColor(for value: Double) -> NSColor {
        if value >= 90 {
            // Red
            return NSColor(hex: 0xEF4444)
        } else if value >= 70 {
            // Orange
            return NSColor(hex: 0xF97316)
        } else if value >= 50 {
            // Yellow
            return NSColor(hex: 0xEAB308)
        } else {
            // Green
            return NSColor(hex: 0x22C55E)
        }
    }
}

// MARK: - NSColor Extension

private extension NSColor {
    convenience init(hex: UInt) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: 1.0
        )
    }
}
