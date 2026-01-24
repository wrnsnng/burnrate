import Foundation

struct KeychainService {
    private static let serviceName = "Claude Code-credentials"

    struct Credentials: Codable {
        let claudeAiOauth: OAuthCredentials?
    }

    struct OAuthCredentials: Codable {
        let accessToken: String?
        let expiresAt: Int64?
    }

    static func getOAuthToken() -> String? {
        guard let credentials = getCredentials() else { return nil }
        return credentials.claudeAiOauth?.accessToken
    }

    static func isTokenExpired() -> Bool {
        guard let credentials = getCredentials(),
              let oauth = credentials.claudeAiOauth,
              let expiresAt = oauth.expiresAt else {
            return true
        }
        // Add 5 minute buffer
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        return now > expiresAt - 300000
    }

    private static func getCredentials() -> Credentials? {
        // Use security command line tool (same as Python version)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        process.arguments = ["find-generic-password", "-s", serviceName, "-w"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else { return nil }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let jsonString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  let jsonData = jsonString.data(using: .utf8) else {
                return nil
            }

            return try JSONDecoder().decode(Credentials.self, from: jsonData)
        } catch {
            return nil
        }
    }
}
