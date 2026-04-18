import Foundation

struct Updater {
    private static let repo       = "0xSiddhant/xcodeproj_audit"
    private static let binaryName = "xcodeproj_audit"

    private static let red    = "\u{1B}[0;31m"
    private static let green  = "\u{1B}[0;32m"
    private static let yellow = "\u{1B}[1;33m"
    private static let reset  = "\u{1B}[0m"

    static func run(currentVersion: String) {
        do {
            print("\(yellow)Checking for updates...\(reset)")
            let latest = try fetchLatestVersion()

            guard latest != currentVersion else {
                print("\(green)\(binaryName) is already up to date (\(currentVersion))\(reset)")
                return
            }

            print("\(yellow)Updating \(binaryName) \(currentVersion) → \(latest)...\(reset)")
            try downloadAndReplace(version: latest)
            print("\(green)\(binaryName) updated \(currentVersion) → \(latest)\(reset)")

        } catch UpdateError.permissionDenied(let path) {
            print("\(red)error: permission denied writing to \(path)\(reset)")
            print("Try running with sudo: sudo xcodeproj_audit --update")
            Foundation.exit(1)
        } catch {
            print("\(red)error: \(error.localizedDescription)\(reset)")
            Foundation.exit(1)
        }
    }

    // MARK: - Private

    private static func fetchLatestVersion() throws -> String {
        let output = try shell(["curl", "-fsSL",
            "https://api.github.com/repos/\(repo)/releases/latest"])

        for line in output.components(separatedBy: "\n") {
            if line.contains("\"tag_name\"") {
                let parts = line.components(separatedBy: "\"")
                if parts.count >= 4 { return parts[3] }
            }
        }
        throw UpdateError.versionNotFound
    }

    private static func downloadAndReplace(version: String) throws {
        let archive = "\(binaryName)-\(version)-macos.zip"
        let url     = "https://github.com/\(repo)/releases/download/\(version)/\(archive)"

        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let zipPath       = tmpDir.appendingPathComponent(archive).path
        let newBinaryPath = tmpDir.appendingPathComponent(binaryName).path

        print("\(yellow)Downloading \(binaryName) \(version)...\(reset)")
        try shell(["curl", "-fsSL", url, "-o", zipPath])
        try shell(["unzip", "-q", zipPath, "-d", tmpDir.path])

        let execPath = resolveExecutablePath()
        do {
            try shell(["install", "-m", "755", newBinaryPath, execPath])
        } catch {
            throw UpdateError.permissionDenied(execPath)
        }
    }

    private static func resolveExecutablePath() -> String {
        Bundle.main.executablePath ?? ProcessInfo.processInfo.arguments[0]
    }

    @discardableResult
    private static func shell(_ args: [String]) throws -> String {
        let process = Process()
        let stdout  = Pipe()
        let stderr  = Pipe()
        process.executableURL    = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments        = args
        process.standardOutput   = stdout
        process.standardError    = stderr
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let errMsg = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw UpdateError.commandFailed(args.joined(separator: " "), errMsg)
        }
        return String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }
}

enum UpdateError: Error, LocalizedError {
    case versionNotFound
    case permissionDenied(String)
    case commandFailed(String, String)

    var errorDescription: String? {
        switch self {
        case .versionNotFound:
            return "could not determine latest version from GitHub API"
        case .permissionDenied(let path):
            return "permission denied writing to \(path)"
        case .commandFailed(let cmd, let output):
            return "command failed: \(cmd)\n\(output)"
        }
    }
}
