import Foundation
import os

private let logger = os.Logger(subsystem: "com.splab.buddi", category: "BuddyStats")

/// Persistent stats for the buddy pet. Tracks XP, level, affection, and lifetime activity.
@MainActor
final class BuddyStats: ObservableObject {
    static let shared = BuddyStats()

    @Published private(set) var data: StatsData

    private static let fileURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Buddi")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("buddy-stats.json")
    }()

    private init() {
        if let loaded = try? Data(contentsOf: Self.fileURL),
           let decoded = try? JSONDecoder().decode(StatsData.self, from: loaded) {
            self.data = decoded
        } else {
            self.data = StatsData()
        }
    }

    // MARK: - XP & Level

    /// XP required to reach a given level: 100 * level^1.5
    static func xpForLevel(_ level: Int) -> Int {
        Int(100.0 * pow(Double(level), 1.5))
    }

    var level: Int { data.level }

    var xpProgress: Double {
        let needed = Self.xpForLevel(data.level + 1) - Self.xpForLevel(data.level)
        let current = data.totalXP - Self.xpForLevel(data.level)
        guard needed > 0 else { return 0 }
        return Double(current) / Double(needed)
    }

    // MARK: - Affection

    /// Affection level as a string
    var affectionTitle: String {
        switch data.affection {
        case 0..<10: "Stranger"
        case 10..<30: "Acquaintance"
        case 30..<60: "Friend"
        case 60..<100: "Close Friend"
        case 100..<200: "Best Friend"
        default: "Soulmate"
        }
    }

    var affectionProgress: Double {
        let thresholds = [0, 10, 30, 60, 100, 200, 500]
        for i in 0..<(thresholds.count - 1) {
            let low = thresholds[i]
            let high = thresholds[i + 1]
            if data.affection < high {
                return Double(data.affection - low) / Double(high - low)
            }
        }
        return 1.0
    }

    // MARK: - Event Recording

    func recordPet() {
        data.petsReceived += 1
        data.affection += 1
        addXP(5)
        save()
    }

    func recordToolApproval() {
        data.toolsApproved += 1
        addXP(10)
        save()
    }

    func recordSessionParticipated() {
        data.sessionsParticipated += 1
        addXP(15)
        save()
    }

    func recordMessageWitnessed() {
        data.messagesWitnessed += 1
        addXP(2)
        save()
    }

    func recordBuddyChat() {
        data.buddyChats += 1
        data.affection += 2
        addXP(8)
        save()
    }

    // MARK: - Private

    private func addXP(_ amount: Int) {
        data.totalXP += amount
        // Check for level-ups
        while data.totalXP >= Self.xpForLevel(data.level + 1) {
            data.level += 1
            logger.debug("Buddy leveled up to \(self.data.level, privacy: .public)!")
        }
    }

    private func save() {
        do {
            let encoded = try JSONEncoder().encode(data)
            try encoded.write(to: Self.fileURL, options: .atomic)
        } catch {
            logger.error("Failed to save buddy stats: \(error.localizedDescription, privacy: .private)")
        }
    }
}

// MARK: - Data Model

extension BuddyStats {
    struct StatsData: Codable {
        var totalXP: Int = 0
        var level: Int = 1
        var affection: Int = 0
        var petsReceived: Int = 0
        var toolsApproved: Int = 0
        var sessionsParticipated: Int = 0
        var messagesWitnessed: Int = 0
        var buddyChats: Int = 0
        var firstMet: Date = Date()
    }
}
