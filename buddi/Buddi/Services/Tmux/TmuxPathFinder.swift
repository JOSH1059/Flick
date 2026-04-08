//
//  TmuxPathFinder.swift
//  Buddi
//
//  Finds tmux and cmux executable paths
//

import Foundation

/// Finds and caches the tmux/cmux executable paths
actor TmuxPathFinder {
    static let shared = TmuxPathFinder()

    private var cachedTmuxPath: String?
    private var cachedCmuxPath: String?

    private init() {}

    /// Get the path to tmux executable
    func getTmuxPath() -> String? {
        if let cached = cachedTmuxPath {
            return cached
        }

        let possiblePaths = [
            "/opt/homebrew/bin/tmux",  // Apple Silicon Homebrew
            "/usr/local/bin/tmux",     // Intel Homebrew
            "/usr/bin/tmux",           // System
            "/bin/tmux"
        ]

        for path in possiblePaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                cachedTmuxPath = path
                return path
            }
        }

        return nil
    }

    /// Get the path to cmux executable
    func getCmuxPath() -> String? {
        if let cached = cachedCmuxPath {
            return cached
        }

        let path = "/Applications/cmux.app/Contents/Resources/bin/cmux"
        if FileManager.default.isExecutableFile(atPath: path) {
            cachedCmuxPath = path
            return path
        }

        return nil
    }

    /// Check if tmux is available
    func isTmuxAvailable() -> Bool {
        getTmuxPath() != nil
    }

    /// Check if cmux is available
    func isCmuxAvailable() -> Bool {
        getCmuxPath() != nil
    }
}
