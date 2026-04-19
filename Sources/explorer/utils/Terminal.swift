//
//  Terminal.swift
//  xcodeproj_audit
//
//  Centralized ANSI colour / styling helpers. All CLI output styling must
//  route through this utility — never emit raw escape codes from other files.
//
import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

enum Terminal {
    private static let reset = "\u{1B}[0m"

    // Process-wide override — set by `--no-color` CLI flag before any output.
    static var forceDisabled: Bool = false

    static var isColorEnabled: Bool {
        if forceDisabled { return false }
        let env = ProcessInfo.processInfo.environment
        if env["NO_COLOR"] != nil { return false }
        if env["TERM"] == "dumb" { return false }
        if isatty(STDOUT_FILENO) == 0 { return false }
        return true
    }

    // MARK: - ANSI primitives

    static func red(_ s: String)    -> String { wrap(s, "\u{1B}[0;31m") }
    static func green(_ s: String)  -> String { wrap(s, "\u{1B}[0;32m") }
    static func yellow(_ s: String) -> String { wrap(s, "\u{1B}[1;33m") }
    static func cyan(_ s: String)   -> String { wrap(s, "\u{1B}[0;36m") }
    static func bold(_ s: String)   -> String { wrap(s, "\u{1B}[1m") }
    static func dim(_ s: String)    -> String { wrap(s, "\u{1B}[2m") }

    // MARK: - Semantic helpers

    static func header(_ s: String)  -> String { bold(s) }
    static func success(_ s: String) -> String { green(s) }
    static func warning(_ s: String) -> String { yellow(s) }
    static func problem(_ s: String) -> String { red(s) }
    static func label(_ s: String)   -> String { dim(s) }
    static func value(_ s: String)   -> String { bold(s) }

    static func separator(_ char: String = "─", count: Int = 50) -> String {
        dim(String(repeating: char, count: count))
    }

    /// Right-aligns an elapsed-time tag onto the same line as `header`,
    /// padding with spaces so the tag ends at column `width`.
    static func appendTiming(to header: String, duration: TimeInterval, width: Int = 50) -> String {
        let ms = Int((duration * 1000).rounded())
        let tag = "\(ms)ms"
        let visibleHeader = stripAnsi(header).count
        let padding = max(1, width - visibleHeader - tag.count)
        return header + String(repeating: " ", count: padding) + dim(tag)
    }

    // MARK: - Private

    private static func stripAnsi(_ s: String) -> String {
        guard s.contains("\u{1B}[") else { return s }
        var out = ""
        var inEscape = false
        for ch in s {
            if inEscape {
                if ch == "m" { inEscape = false }
                continue
            }
            if ch == "\u{1B}" {
                inEscape = true
                continue
            }
            out.append(ch)
        }
        return out
    }

    private static func wrap(_ s: String, _ code: String) -> String {
        guard !s.isEmpty, isColorEnabled else { return s }
        return "\(code)\(s)\(reset)"
    }
}
