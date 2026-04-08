//
//  NotificationSound.swift
//  Buddi
//
//  Notification sound enum and settings adapter
//

import Foundation
import Defaults

/// Available notification sounds
enum NotificationSound: String, CaseIterable {
    case none = "None"
    case pop = "Pop"
    case ping = "Ping"
    case tink = "Tink"
    case glass = "Glass"
    case blow = "Blow"
    case bottle = "Bottle"
    case frog = "Frog"
    case funk = "Funk"
    case hero = "Hero"
    case morse = "Morse"
    case purr = "Purr"
    case sosumi = "Sosumi"
    case submarine = "Submarine"
    case basso = "Basso"

    /// The system sound name to use with NSSound, or nil for no sound
    var soundName: String? {
        self == .none ? nil : rawValue
    }
}

enum BuddiSettings {
    static var notificationSound: NotificationSound {
        get { NotificationSound(rawValue: Defaults[.notificationSound]) ?? .pop }
        set { Defaults[.notificationSound] = newValue.rawValue }
    }
}
