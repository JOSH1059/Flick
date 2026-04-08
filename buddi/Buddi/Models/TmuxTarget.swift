//
//  TmuxTarget.swift
//  Buddi
//
//  Data model for tmux/cmux session/window/pane targeting
//

import Foundation

/// Which terminal multiplexer owns the target
enum MultiplexerType: Sendable {
    case tmux
    case cmux
}

/// Represents a multiplexer target (tmux session:window.pane or cmux workspace/surface)
struct TmuxTarget: Sendable {
    let session: String
    let window: String
    let pane: String
    let multiplexer: MultiplexerType

    /// For tmux: "session:window.pane"; for cmux: the surface ref (stored in `pane`)
    nonisolated var targetString: String {
        switch multiplexer {
        case .tmux:
            return "\(session):\(window).\(pane)"
        case .cmux:
            // For cmux, pane holds the surface ref (e.g. "surface:76")
            return pane
        }
    }

    /// The cmux workspace ref (stored in `session` for cmux targets)
    nonisolated var cmuxWorkspaceRef: String? {
        guard multiplexer == .cmux else { return nil }
        return session
    }

    /// The cmux surface ref (stored in `pane` for cmux targets)
    nonisolated var cmuxSurfaceRef: String? {
        guard multiplexer == .cmux else { return nil }
        return pane
    }

    nonisolated init(session: String, window: String, pane: String, multiplexer: MultiplexerType = .tmux) {
        self.session = session
        self.window = window
        self.pane = pane
        self.multiplexer = multiplexer
    }

    /// Create a cmux target from workspace and surface refs
    nonisolated static func cmux(workspace: String, surface: String) -> TmuxTarget {
        TmuxTarget(session: workspace, window: "", pane: surface, multiplexer: .cmux)
    }

    /// Parse from tmux target string format "session:window.pane"
    nonisolated init?(from targetString: String) {
        let sessionSplit = targetString.split(separator: ":", maxSplits: 1)
        guard sessionSplit.count == 2 else { return nil }

        let session = String(sessionSplit[0])
        let windowPane = String(sessionSplit[1])

        let paneSplit = windowPane.split(separator: ".", maxSplits: 1)
        guard paneSplit.count == 2 else { return nil }

        self.session = session
        self.window = String(paneSplit[0])
        self.pane = String(paneSplit[1])
        self.multiplexer = .tmux
    }
}
