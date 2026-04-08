//
//  AppStubs.swift
//  Buddi
//
//  Stub types for app-level code that references app-level types
//  not ported into buddi. These are minimal stubs to allow compilation.
//

import Foundation
import SwiftUI

// MARK: - UpdateManager Stub

@MainActor
class UpdateManager: ObservableObject {
    static let shared = UpdateManager()

    enum UpdateState: Equatable {
        case idle
        case checking
        case upToDate
        case found(String, URL? = nil)
        case downloading(Double)
        case extracting(Double)
        case readyToInstall(String)
        case installing
        case error(String)

        static func == (lhs: UpdateState, rhs: UpdateState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.checking, .checking), (.upToDate, .upToDate), (.installing, .installing):
                return true
            case (.found(let a, _), .found(let b, _)):
                return a == b
            case (.downloading(let a), .downloading(let b)):
                return a == b
            case (.extracting(let a), .extracting(let b)):
                return a == b
            case (.readyToInstall(let a), .readyToInstall(let b)):
                return a == b
            case (.error(let a), .error(let b)):
                return a == b
            default:
                return false
            }
        }
    }

    @Published var state: UpdateState = .idle

    var hasUnseenUpdate: Bool { false }

    func checkForUpdates() {}
    func markUpdateSeen() {}
    func downloadAndInstall() {}
    func installAndRelaunch() {}
    func installUpdate() {}
}
