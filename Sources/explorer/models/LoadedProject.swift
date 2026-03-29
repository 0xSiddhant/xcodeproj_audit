//
//  LoadedProject.swift
//  xcproj_explorer
//
//  Created by Siddhant Kumar on 29/03/26.
//
import PathKit
import XcodeProj

struct LoadedProject {
    let path: Path
    let project: XcodeProj
    let isVendored: Bool        // true = Pods / Carthage / SPM checkout
}
