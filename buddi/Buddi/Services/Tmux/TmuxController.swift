//
//  TmuxController.swift
//  Buddi
//
//  High-level tmux operations controller
//

import Foundation

/// Controller for tmux operations
actor TmuxController {
    static let shared = TmuxController()

    private init() {}

    func findTmuxTarget(forClaudePid pid: Int) async -> TmuxTarget? {
        await TmuxTargetFinder.shared.findTarget(forClaudePid: pid)
    }

    func findTmuxTarget(forWorkingDirectory dir: String) async -> TmuxTarget? {
        await TmuxTargetFinder.shared.findTarget(forWorkingDirectory: dir)
    }

    func sendMessage(_ message: String, to target: TmuxTarget) async -> Bool {
        await ToolApprovalHandler.shared.sendMessage(message, to: target)
    }

    func approveOnce(target: TmuxTarget) async -> Bool {
        await ToolApprovalHandler.shared.approveOnce(target: target)
    }

    func approveAlways(target: TmuxTarget) async -> Bool {
        await ToolApprovalHandler.shared.approveAlways(target: target)
    }

    func reject(target: TmuxTarget, message: String? = nil) async -> Bool {
        await ToolApprovalHandler.shared.reject(target: target, message: message)
    }

    func switchToPane(target: TmuxTarget) async -> Bool {
        switch target.multiplexer {
        case .tmux:
            return await switchToTmuxPane(target: target)
        case .cmux:
            return await switchToCmuxSurface(target: target)
        }
    }

    private func switchToTmuxPane(target: TmuxTarget) async -> Bool {
        guard let tmuxPath = await TmuxPathFinder.shared.getTmuxPath() else {
            return false
        }

        do {
            _ = try await ProcessExecutor.shared.run(tmuxPath, arguments: [
                "select-window", "-t", "\(target.session):\(target.window)"
            ])

            _ = try await ProcessExecutor.shared.run(tmuxPath, arguments: [
                "select-pane", "-t", target.targetString
            ])

            return true
        } catch {
            return false
        }
    }

    private func switchToCmuxSurface(target: TmuxTarget) async -> Bool {
        guard let cmuxPath = await TmuxPathFinder.shared.getCmuxPath() else {
            return false
        }

        guard let workspace = target.cmuxWorkspaceRef,
              let surface = target.cmuxSurfaceRef else {
            return false
        }

        do {
            // Select the workspace first, then focus the pane
            _ = try await ProcessExecutor.shared.run(cmuxPath, arguments: [
                "select-workspace", "--workspace", workspace
            ])

            // Move the surface into focus (cmux uses surface ref for tab focus)
            _ = try await ProcessExecutor.shared.run(cmuxPath, arguments: [
                "tab-action", "--action", "select", "--surface", surface, "--workspace", workspace
            ])

            return true
        } catch {
            return false
        }
    }
}
