import AppKit

enum BuddySpecies: String, CaseIterable, Codable {
    case duck
    case goose
    case blob
    case cat
    case dragon
    case octopus
    case owl
    case penguin
    case turtle
    case snail
    case ghost
    case axolotl
    case capybara
    case cactus
    case robot
    case rabbit
    case mushroom
    case chonk
}

enum BuddyRarity: String, CaseIterable, Codable {
    case common
    case uncommon
    case rare
    case epic
    case legendary

    var weight: Int {
        switch self {
        case .common: 60
        case .uncommon: 25
        case .rare: 10
        case .epic: 4
        case .legendary: 1
        }
    }

    var statFloor: Int {
        switch self {
        case .common: 5
        case .uncommon: 15
        case .rare: 25
        case .epic: 35
        case .legendary: 50
        }
    }

    var nsColor: NSColor {
        switch self {
        case .common: .labelColor
        case .uncommon: .systemGreen
        case .rare: .systemBlue
        case .epic: .systemPurple
        case .legendary: .systemYellow
        }
    }

    var stars: String {
        switch self {
        case .common: "★"
        case .uncommon: "★★"
        case .rare: "★★★"
        case .epic: "★★★★"
        case .legendary: "★★★★★"
        }
    }
}

enum BuddyEye: String, CaseIterable, Codable {
    case dot = "·"
    case spark = "✦"
    case cross = "×"
    case target = "◉"
    case at = "@"
    case degree = "°"

    var name: String {
        switch self {
        case .dot: "Dot"
        case .spark: "Spark"
        case .cross: "Cross"
        case .target: "Target"
        case .at: "At"
        case .degree: "Degree"
        }
    }
}

enum BuddyHat: String, CaseIterable, Codable {
    case none
    case crown
    case tophat
    case propeller
    case halo
    case wizard
    case beanie
    case tinyduck
}

struct BuddyIdentity: Equatable {
    var species: BuddySpecies
    var rarity: BuddyRarity
    var eye: BuddyEye
    var hat: BuddyHat
    var name: String?
}
