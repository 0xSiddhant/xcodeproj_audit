import Foundation
import PathKit
import XcodeProj

struct LocalSPMPackageReader {
    private init() {}

    /// Returns resolved absolute roots for all local SPM packages in the pbxproj.
    /// Skips any path that does not exist on disk as a directory.
    static func findLocalPackageRoots(pbxproj: PBXProj, projectRoot: Path) -> [Path] {
        let localRefs = pbxproj.rootObject?.localPackages ?? []
        return localRefs.compactMap { ref -> Path? in
            guard let relativePath = ref.relativePath else { return nil }
            let packageRoot = (projectRoot + relativePath).normalize()
            guard packageRoot.isDirectory else { return nil }
            return packageRoot
        }
    }

    /// Recursively enumerates source files under a package root,
    /// filtered by config.includedExtensions and config.excludedPathFragments.
    static func resolveSourceFiles(packageRoot: Path, config: DashboardConfig) -> [Path] {
        guard let enumerator = FileManager.default.enumerator(
            at: URL(fileURLWithPath: packageRoot.string),
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return enumerator.compactMap { item -> Path? in
            guard let url = item as? URL,
                  (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true
            else { return nil }
            let path = Path(url.path)
            guard let ext = path.extension,
                  config.includedExtensions.contains(ext),
                  !config.excludedPathFragments.contains(where: { path.string.contains($0) })
            else { return nil }
            return path
        }
    }
}
