import SwiftUI

struct ExtraUsageView: View {
    let accountInfo: AccountInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Extra Usage", systemImage: "creditcard.fill")
                .font(.headline)
                .foregroundStyle(.primary)

            HStack(spacing: 6) {
                Image(systemName: accountInfo.hasExtraUsageEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(accountInfo.hasExtraUsageEnabled ? .green : .secondary)

                Text(accountInfo.hasExtraUsageEnabled ? "Enabled" : "Not enabled")
                    .font(.subheadline)
                    .foregroundStyle(accountInfo.hasExtraUsageEnabled ? .primary : .secondary)
            }
            .padding(.leading, 4)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ExtraUsageView(accountInfo: AccountInfo(hasExtraUsageEnabled: true, billingType: "pro", email: "test@example.com"))
        ExtraUsageView(accountInfo: AccountInfo(hasExtraUsageEnabled: false, billingType: "free", email: nil))
    }
    .padding()
    .frame(width: 280)
}
