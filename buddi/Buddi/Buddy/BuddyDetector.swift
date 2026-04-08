import Foundation

enum BuddyDetector {
    static let defaultSalt = "friend-2026-401"

    static func detectUserId() -> String {
        loadConfig()?.userId ?? "anon"
    }

    static func roll(userId: String, salt: String = defaultSalt) -> BuddyIdentity {
        let hash = Wyhash.hash(seed: 0, key: userId + salt)
        let seed = UInt32(truncatingIfNeeded: hash)
        var rng = Mulberry32(seed: seed)

        let rarity = rollRarity(rng: &rng)
        let species = pick(rng: &rng, from: BuddySpecies.allCases)
        let eye = pick(rng: &rng, from: BuddyEye.allCases)
        let hat: BuddyHat = rarity == .common ? .none : pick(rng: &rng, from: BuddyHat.allCases)

        return BuddyIdentity(
            species: species,
            rarity: rarity,
            eye: eye,
            hat: hat,
            name: nil
        )
    }

    static func detect(salt: String = defaultSalt) -> BuddyIdentity {
        let config = loadConfig()
        let userId = config?.userId ?? "anon"
        var identity = roll(userId: userId, salt: salt)
        identity.name = config?.companion?.name
        return identity
    }

    private static func rollRarity(rng: inout Mulberry32) -> BuddyRarity {
        let total = BuddyRarity.allCases.reduce(0) { $0 + $1.weight }
        var roll = rng.next() * Double(total)
        for rarity in BuddyRarity.allCases {
            roll -= Double(rarity.weight)
            if roll < 0 {
                return rarity
            }
        }
        return .common
    }

    private static func pick<T>(rng: inout Mulberry32, from values: [T]) -> T {
        let index = Int(floorDouble(rng.next() * Double(values.count)))
        return values[min(index, values.count - 1)]
    }

    private static func floorDouble(_ value: Double) -> Double {
        Foundation.floor(value)
    }

    private static func loadConfig() -> ClaudeConfig? {
        for path in configCandidates() {
            guard FileManager.default.fileExists(atPath: path.path) else {
                continue
            }

            guard let data = try? Data(contentsOf: path) else {
                continue
            }

            let decoder = JSONDecoder()
            if let config = try? decoder.decode(ClaudeConfig.self, from: data) {
                return config
            }
        }

        return nil
    }

    private static func configCandidates() -> [URL] {
        var candidates: [URL] = []

        if let custom = ProcessInfo.processInfo.environment["CLAUDE_CONFIG_DIR"], !custom.isEmpty {
            let customURL = URL(fileURLWithPath: NSString(string: custom).expandingTildeInPath)
            if customURL.pathExtension == "json" {
                candidates.append(customURL)
            } else {
                candidates.append(customURL.appendingPathComponent(".claude.json"))
                candidates.append(customURL.appendingPathComponent(".config.json"))
                candidates.append(customURL.appendingPathComponent("config.json"))
            }
        }

        let home = FileManager.default.homeDirectoryForCurrentUser
        candidates.append(home.appendingPathComponent(".claude.json"))
        candidates.append(home.appendingPathComponent(".claude/.config.json"))

        var unique: [URL] = []
        var seen = Set<String>()
        for candidate in candidates {
            if seen.insert(candidate.path).inserted {
                unique.append(candidate)
            }
        }
        return unique
    }
}

private struct ClaudeConfig: Decodable {
    struct OAuthAccount: Decodable {
        let accountUuid: String?
    }

    struct CompanionSoul: Decodable {
        let name: String?
        let personality: String?
    }

    let oauthAccount: OAuthAccount?
    let userID: String?
    let companion: CompanionSoul?

    var userId: String? {
        oauthAccount?.accountUuid ?? userID
    }
}
