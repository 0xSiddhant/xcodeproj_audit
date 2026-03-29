// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import PathKit
import XcodeProj

@main
struct xcproj_explorer: ParsableCommand {
    @Option(transform: { argument in Path.current + argument })
    var path: Path
    
    mutating func run() throws {
        print("Hello, world!")
        
        //1
        print("Analyzing .xcodeproj at:", path)

        //2
        let xcodeProj = try XcodeProj(path: path)

        //3
        try xcodeProj.pbxproj.projects.forEach { pbxProject in
          //4
          print("Project \(pbxProject.name):")
          print("\t・\(pbxProject.remotePackages.count) remote package(s)")
          print("\t・\(pbxProject.localPackages.count) local package(s)")
          print("")
          try analyzeProjectTargets(pbxProject.targets)
        }
    }
    
    private func analyzeProjectTargets(_ targets: [PBXTarget]) throws {
      try targets.forEach { target in
        print("\t・Target \(target.name) \((target.productType?.fileExtension ?? "")):")
        print("\t\t・\(try target.sourceFiles().count) source file(s)")
        print("\t\t・\(try target.resourcesBuildPhase()?.files?.count ?? 0) resource(s)")
          print("\t\t・\(target.packageProductDependencies?.count) package dependencies")
        print("\t\t・\(target.dependencies.count) dependencies")
        print("")
      }
    }
}
