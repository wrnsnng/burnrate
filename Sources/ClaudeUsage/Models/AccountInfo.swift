import Foundation

struct AccountInfo {
    let hasExtraUsageEnabled: Bool
    let billingType: String
    let email: String?

    static let empty = AccountInfo(
        hasExtraUsageEnabled: false,
        billingType: "unknown",
        email: nil
    )
}
