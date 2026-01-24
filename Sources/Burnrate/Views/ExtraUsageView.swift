import SwiftUI

struct ExtraUsageView: View {
    let accountInfo: AccountInfo

    var body: some View {
        HStack(spacing: BurnrateTheme.spacingMD) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(accountInfo.hasExtraUsageEnabled
                          ? BurnrateTheme.statusGreen.opacity(0.15)
                          : BurnrateTheme.cardBackground)
                    .frame(width: 28, height: 28)

                Image(systemName: accountInfo.hasExtraUsageEnabled
                      ? "checkmark.circle.fill"
                      : "xmark.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accountInfo.hasExtraUsageEnabled
                                     ? BurnrateTheme.statusGreen
                                     : BurnrateTheme.textTertiary)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("Extra usage")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(BurnrateTheme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.3)

                Text(accountInfo.hasExtraUsageEnabled ? "Enabled" : "Not enabled")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(accountInfo.hasExtraUsageEnabled
                                     ? BurnrateTheme.textPrimary
                                     : BurnrateTheme.textTertiary)
            }

            Spacer()
        }
        .padding(BurnrateTheme.spacingMD)
        .background(
            RoundedRectangle(cornerRadius: BurnrateTheme.radiusSM)
                .fill(BurnrateTheme.cardBackground)
        )
    }
}

#Preview {
    VStack(spacing: 12) {
        ExtraUsageView(accountInfo: AccountInfo(hasExtraUsageEnabled: true, billingType: "pro", email: "test@example.com"))
        ExtraUsageView(accountInfo: AccountInfo(hasExtraUsageEnabled: false, billingType: "free", email: nil))
    }
    .padding()
    .frame(width: 320)
    .background(Color(NSColor.windowBackgroundColor))
}
