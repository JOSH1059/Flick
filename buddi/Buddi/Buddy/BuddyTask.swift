enum BuddyTask: String, CaseIterable {
    case idle
    case working
    case reading
    case sleeping
    case compacting
    case waiting
    case error
    case success
    case happy
    case petting

    var faceSuffix: String {
        switch self {
        case .idle: ""
        case .working: "..."
        case .reading: "..."
        case .sleeping: " zzz"
        case .compacting: "~"
        case .waiting: "?"
        case .error: "!"
        case .success: "✓"
        case .happy: " ♥"
        case .petting: " ♥♥♥"
        }
    }
}
