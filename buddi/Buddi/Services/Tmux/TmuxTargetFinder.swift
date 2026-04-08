//
//  TmuxTargetFinder.swift
//  Buddi
//
//  Finds tmux/cmux targets for Claude processes
//

import Foundation

/// Finds tmux/cmux session/window/pane targets for Claude processes
actor TmuxTargetFinder {
    static let shared = TmuxTargetFinder()

    private init() {}

    /// Find the multiplexer target for a given Claude PID (tries tmux first, then cmux)
    func findTarget(forClaudePid claudePid: Int) async -> TmuxTarget? {
        // Try tmux first
        if let tmuxTarget = await findTmuxTarget(forClaudePid: claudePid) {
            return tmuxTarget
        }

        // Fall back to cmux
        return await findCmuxTarget(forClaudePid: claudePid)
    }

    /// Find the multiplexer target for a given working directory (tries tmux first, then cmux)
    func findTarget(forWorkingDirectory workingDir: String) async -> TmuxTarget? {
        // Try tmux first
        if let tmuxTarget = await findTmuxTargetByDir(workingDir: workingDir) {
            return tmuxTarget
        }

        // Fall back to cmux
        return await findCmuxTarget(forWorkingDirectory: workingDir)
    }

    /// Check if a session's pane is currently the active/focused pane
    func isSessionPaneActive(claudePid: Int) async -> Bool {
        let tree = ProcessTreeBuilder.shared.buildTree()

        // Check tmux
        if ProcessTreeBuilder.shared.isInTmux(pid: claudePid, tree: tree) {
            return await isTmuxPaneActive(claudePid: claudePid)
        }

        // Check cmux
        if ProcessTreeBuilder.shared.isInCmux(pid: claudePid, tree: tree) {
            return await isCmuxSurfaceActive(claudePid: claudePid)
        }

        return false
    }

    // MARK: - tmux Target Finding

    private func findTmuxTarget(forClaudePid claudePid: Int) async -> TmuxTarget? {
        guard let tmuxPath = await TmuxPathFinder.shared.getTmuxPath() else {
            return nil
        }

        guard let output = await runCommand(path: tmuxPath, args: [
            "list-panes", "-a", "-F", "#{session_name}:#{window_index}.#{pane_index} #{pane_pid}"
        ]) else {
            return nil
        }

        let tree = ProcessTreeBuilder.shared.buildTree()

        for line in output.components(separatedBy: "\n") {
            let parts = line.split(separator: " ", maxSplits: 1)
            guard parts.count == 2,
                  let panePid = Int(parts[1]) else { continue }

            let targetString = String(parts[0])

            if ProcessTreeBuilder.shared.isDescendant(targetPid: claudePid, ofAncestor: panePid, tree: tree) {
                return TmuxTarget(from: targetString)
            }
        }

        return nil
    }

    private func findTmuxTargetByDir(workingDir: String) async -> TmuxTarget? {
        guard let tmuxPath = await TmuxPathFinder.shared.getTmuxPath() else {
            return nil
        }

        guard let output = await runCommand(path: tmuxPath, args: [
            "list-panes", "-a", "-F", "#{session_name}:#{window_index}.#{pane_index} #{pane_current_path}"
        ]) else {
            return nil
        }

        for line in output.components(separatedBy: "\n") {
            let parts = line.split(separator: " ", maxSplits: 1)
            guard parts.count == 2 else { continue }

            let targetString = String(parts[0])
            let panePath = String(parts[1])

            if panePath == workingDir {
                return TmuxTarget(from: targetString)
            }
        }

        return nil
    }

    private func isTmuxPaneActive(claudePid: Int) async -> Bool {
        guard let tmuxPath = await TmuxPathFinder.shared.getTmuxPath() else {
            return false
        }

        guard let sessionTarget = await findTmuxTarget(forClaudePid: claudePid) else {
            return false
        }

        guard let output = await runCommand(path: tmuxPath, args: [
            "display-message", "-p", "#{session_name}:#{window_index}.#{pane_index}"
        ]) else {
            return false
        }

        let activeTarget = output.trimmingCharacters(in: .whitespacesAndNewlines)
        return sessionTarget.targetString == activeTarget
    }

    // MARK: - cmux Target Finding

    /// Find cmux surface for a Claude PID by matching process tree to surface content
    private func findCmuxTarget(forClaudePid claudePid: Int) async -> TmuxTarget? {
        guard let cmuxPath = await TmuxPathFinder.shared.getCmuxPath() else {
            return nil
        }

        let tree = ProcessTreeBuilder.shared.buildTree()

        // Verify the Claude process is actually in cmux
        guard ProcessTreeBuilder.shared.isInCmux(pid: claudePid, tree: tree) else {
            return nil
        }

        // Get all cmux surfaces across all workspaces
        let surfaces = await enumerateCmuxSurfaces(cmuxPath: cmuxPath)

        // Get the working directory of the Claude process for matching
        let claudeCwd = ProcessTreeBuilder.shared.getWorkingDirectory(forPid: claudePid)

        for surface in surfaces {
            guard surface.type == "terminal" else { continue }

            // Read screen content and check for the working directory or project path
            if let claudeCwd = claudeCwd {
                let cwdName = URL(fileURLWithPath: claudeCwd).lastPathComponent
                if let content = await readCmuxScreen(
                    cmuxPath: cmuxPath, workspace: surface.workspace, surface: surface.ref, lines: 10
                ) {
                    if content.contains(cwdName) {
                        return .cmux(workspace: surface.workspace, surface: surface.ref)
                    }
                }
            }
        }

        // Fallback: try matching by surface title
        for surface in surfaces {
            guard surface.type == "terminal" else { continue }

            if let claudeCwd = claudeCwd {
                let projectName = URL(fileURLWithPath: claudeCwd).lastPathComponent
                if surface.title.localizedCaseInsensitiveContains(projectName) {
                    return .cmux(workspace: surface.workspace, surface: surface.ref)
                }
            }
        }

        return nil
    }

    /// Find cmux surface for a working directory
    private func findCmuxTarget(forWorkingDirectory workingDir: String) async -> TmuxTarget? {
        guard let cmuxPath = await TmuxPathFinder.shared.getCmuxPath() else {
            return nil
        }

        let dirName = URL(fileURLWithPath: workingDir).lastPathComponent
        let surfaces = await enumerateCmuxSurfaces(cmuxPath: cmuxPath)

        for surface in surfaces {
            guard surface.type == "terminal" else { continue }

            // Check screen content for the directory
            if let content = await readCmuxScreen(
                cmuxPath: cmuxPath, workspace: surface.workspace, surface: surface.ref, lines: 10
            ) {
                if content.contains(dirName) {
                    return .cmux(workspace: surface.workspace, surface: surface.ref)
                }
            }
        }

        return nil
    }

    private func isCmuxSurfaceActive(claudePid: Int) async -> Bool {
        guard let cmuxPath = await TmuxPathFinder.shared.getCmuxPath() else {
            return false
        }

        guard let target = await findCmuxTarget(forClaudePid: claudePid) else {
            return false
        }

        // Get the currently focused surface
        guard let identifyOutput = await runCommand(path: cmuxPath, args: ["--json", "identify"]) else {
            return false
        }

        guard let data = identifyOutput.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let focused = json["focused"] as? [String: Any],
              let focusedSurface = focused["surface_ref"] as? String else {
            return false
        }

        return target.cmuxSurfaceRef == focusedSurface
    }

    // MARK: - cmux Helpers

    /// A cmux surface with its metadata
    private struct CmuxSurface {
        let workspace: String
        let pane: String
        let ref: String
        let type: String
        let title: String
    }

    /// Enumerate all cmux terminal surfaces across all workspaces
    private func enumerateCmuxSurfaces(cmuxPath: String) async -> [CmuxSurface] {
        // Get all workspaces
        guard let wsOutput = await runCommand(path: cmuxPath, args: ["--json", "list-workspaces"]) else {
            return []
        }

        guard let wsData = wsOutput.data(using: .utf8),
              let wsJson = try? JSONSerialization.jsonObject(with: wsData) as? [String: Any],
              let workspaces = wsJson["workspaces"] as? [[String: Any]] else {
            return []
        }

        var allSurfaces: [CmuxSurface] = []

        for ws in workspaces {
            guard let wsRef = ws["ref"] as? String else { continue }

            // Get panes for this workspace
            guard let panesOutput = await runCommand(
                path: cmuxPath, args: ["--json", "list-panes", "--workspace", wsRef]
            ) else { continue }

            guard let panesData = panesOutput.data(using: .utf8),
                  let panesJson = try? JSONSerialization.jsonObject(with: panesData) as? [String: Any],
                  let panes = panesJson["panes"] as? [[String: Any]] else { continue }

            for pane in panes {
                guard let paneRef = pane["ref"] as? String,
                      let surfaceRefs = pane["surface_refs"] as? [String] else { continue }

                // Get surface details
                guard let surfOutput = await runCommand(
                    path: cmuxPath,
                    args: ["--json", "list-pane-surfaces", "--workspace", wsRef, "--pane", paneRef]
                ) else { continue }

                guard let surfData = surfOutput.data(using: .utf8),
                      let surfJson = try? JSONSerialization.jsonObject(with: surfData) as? [String: Any],
                      let surfaces = surfJson["surfaces"] as? [[String: Any]] else { continue }

                for surface in surfaces {
                    guard let sRef = surface["ref"] as? String,
                          let sType = surface["type"] as? String else { continue }

                    let title = surface["title"] as? String ?? ""
                    allSurfaces.append(CmuxSurface(
                        workspace: wsRef, pane: paneRef, ref: sRef, type: sType, title: title
                    ))
                }
            }
        }

        return allSurfaces
    }

    /// Read screen content from a cmux surface
    private func readCmuxScreen(cmuxPath: String, workspace: String, surface: String, lines: Int) async -> String? {
        guard let output = await runCommand(path: cmuxPath, args: [
            "--json", "read-screen", "--workspace", workspace, "--surface", surface, "--lines", String(lines)
        ]) else {
            return nil
        }

        guard let data = output.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let text = json["text"] as? String else {
            return nil
        }

        return text.isEmpty ? nil : text
    }

    // MARK: - Common Helpers

    private func runCommand(path: String, args: [String]) async -> String? {
        do {
            return try await ProcessExecutor.shared.run(path, arguments: args)
        } catch {
            return nil
        }
    }
}
