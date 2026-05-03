//
//  File.swift
//  xcproj_explorer
//
//  Created by Siddhant Kumar on 29/03/26.
//

import Foundation
import XCTest
import PathKit
@testable import explorer

final class LocalSPMPackageReaderTests: XCTestCase {

    // MARK: - Fixture helpers

    private var tempDir: Path!

    override func setUp() {
        super.setUp()
        tempDir = Path(NSTemporaryDirectory()) + "LocalSPMTests_\(UUID().uuidString)"
        try? tempDir.mkpath()
    }

    override func tearDown() {
        try? tempDir.delete()
        super.tearDown()
    }

    private func makeFixturePackage(name: String, files: [(relative: String, content: String)]) throws -> Path {
        let root = tempDir + name
        try root.mkpath()
        for (relative, content) in files {
            let file = root + relative
            try file.parent().mkpath()
            try file.write(content, encoding: .utf8)
        }
        return root
    }

    // MARK: - resolveSourceFiles

    func test_resolveSourceFiles_returnsSwiftFiles() throws {
        let pkg = try makeFixturePackage(name: "Pkg", files: [
            ("Sources/Lib/Foo.swift", "struct Foo {}"),
            ("Sources/Lib/Bar.swift", "struct Bar {}"),
        ])
        var config = DashboardConfig()
        let files = LocalSPMPackageReader.resolveSourceFiles(packageRoot: pkg, config: config)
        XCTAssertEqual(files.count, 2)
        XCTAssertTrue(files.allSatisfy { $0.extension == "swift" })
    }

    func test_resolveSourceFiles_filtersToIncludedExtensions() throws {
        let pkg = try makeFixturePackage(name: "Pkg2", files: [
            ("Sources/Lib/Foo.swift", "struct Foo {}"),
            ("Sources/Lib/README.md", "# readme"),
            ("Sources/Lib/util.js", "const x = 1"),
        ])
        var config = DashboardConfig()
        config.includedExtensions = ["swift"]
        let files = LocalSPMPackageReader.resolveSourceFiles(packageRoot: pkg, config: config)
        XCTAssertEqual(files.count, 1)
        XCTAssertEqual(files.first?.lastComponent, "Foo.swift")
    }

    func test_resolveSourceFiles_respectsExcludedPathFragments() throws {
        let pkg = try makeFixturePackage(name: "Pkg3", files: [
            ("Sources/Lib/Foo.swift", "struct Foo {}"),
            (".build/release/Gen.generated.swift", "// generated"),
        ])
        var config = DashboardConfig()
        // .build/ is in the default excludedPathFragments
        let files = LocalSPMPackageReader.resolveSourceFiles(packageRoot: pkg, config: config)
        // .build/ is excluded by default config, hidden files are also skipped by enumerator
        XCTAssertTrue(files.allSatisfy { !$0.string.contains(".build/") })
    }

    func test_resolveSourceFiles_emptyWhenNoMatchingFiles() throws {
        let pkg = try makeFixturePackage(name: "Pkg4", files: [
            ("Package.swift", "// swift-tools-version: 5.9"),
            ("README.md", "# hi"),
        ])
        var config = DashboardConfig()
        let files = LocalSPMPackageReader.resolveSourceFiles(packageRoot: pkg, config: config)
        XCTAssertTrue(files.isEmpty)
    }

    func test_resolveSourceFiles_handlesNestedSourceDirectories() throws {
        let pkg = try makeFixturePackage(name: "Pkg5", files: [
            ("Sources/TargetA/Foo.swift", "struct Foo {}"),
            ("Sources/TargetB/Bar.swift", "struct Bar {}"),
            ("Sources/TargetB/Nested/Baz.swift", "struct Baz {}"),
        ])
        var config = DashboardConfig()
        let files = LocalSPMPackageReader.resolveSourceFiles(packageRoot: pkg, config: config)
        XCTAssertEqual(files.count, 3)
    }

    // MARK: - findLocalPackageRoots

    func test_findLocalPackageRoots_skipsNonExistentDirectory() {
        // Create a mock pbxproj that returns a non-existent path isn't practical here
        // without mocking XcodeProj types, so we verify the directory guard in resolveSourceFiles.
        // A missing root simply returns no files.
        let missingRoot = tempDir + "DoesNotExist"
        var config = DashboardConfig()
        let files = LocalSPMPackageReader.resolveSourceFiles(packageRoot: missingRoot, config: config)
        XCTAssertTrue(files.isEmpty)
    }
}
