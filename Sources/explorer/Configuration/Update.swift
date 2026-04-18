import ArgumentParser

struct Update: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Update xcodeproj_audit to the latest release"
    )

    mutating func run() throws {
        // XCProjAudit.configuration.version is kept in sync by the release CI workflow,
        // which rewrites the version string in source before tagging each release.
        Updater.run(currentVersion: XCProjAudit.configuration.version)
    }
}
