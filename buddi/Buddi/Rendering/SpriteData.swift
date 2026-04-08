import Foundation

enum SpriteData {
    static let bodies: [BuddySpecies: [[String]]] = [
        .duck: [
            ["            ", "    __      ", "  <({E} )___  ", "   (  ._>   ", "    `--´    "],
            ["            ", "    __      ", "  <({E} )___  ", "   (  ._>   ", "    `--´~   "],
            ["            ", "    __      ", "  <({E} )___  ", "   (  .__>  ", "    `--´    "],
        ],
        .goose: [
            ["            ", "     ({E}>    ", "     ||     ", "   _(__)_   ", "    ^^^^    "],
            ["            ", "    ({E}>     ", "     ||     ", "   _(__)_   ", "    ^^^^    "],
            ["            ", "     ({E}>>   ", "     ||     ", "   _(__)_   ", "    ^^^^    "],
        ],
        .blob: [
            ["            ", "   .----.   ", "  ( {E}  {E} )  ", "  (      )  ", "   `----´   "],
            ["            ", "  .------.  ", " (  {E}  {E}  ) ", " (        ) ", "  `------´  "],
            ["            ", "    .--.    ", "   ({E}  {E})   ", "   (    )   ", "    `--´    "],
        ],
        .cat: [
            ["            ", "   /\\_/\\    ", "  ( {E}   {E})  ", "  (  ω  )   ", "  (\")_(\")   "],
            ["            ", "   /\\_/\\    ", "  ( {E}   {E})  ", "  (  ω  )   ", "  (\")_(\")~  "],
            ["            ", "   /\\-/\\    ", "  ( {E}   {E})  ", "  (  ω  )   ", "  (\")_(\")   "],
        ],
        .dragon: [
            ["            ", "  /^\\  /^\\  ", " <  {E}  {E}  > ", " (   ~~   ) ", "  `-vvvv-´  "],
            ["            ", "  /^\\  /^\\  ", " <  {E}  {E}  > ", " (        ) ", "  `-vvvv-´  "],
            ["   ~    ~   ", "  /^\\  /^\\  ", " <  {E}  {E}  > ", " (   ~~   ) ", "  `-vvvv-´  "],
        ],
        .octopus: [
            ["            ", "   .----.   ", "  ( {E}  {E} )  ", "  (______)  ", "  /\\/\\/\\/\\  "],
            ["            ", "   .----.   ", "  ( {E}  {E} )  ", "  (______)  ", "  \\/\\/\\/\\/  "],
            ["     o      ", "   .----.   ", "  ( {E}  {E} )  ", "  (______)  ", "  /\\/\\/\\/\\  "],
        ],
        .owl: [
            ["            ", "   /\\  /\\   ", "  (({E})({E}))  ", "  (  ><  )  ", "   `----´   "],
            ["            ", "   /\\  /\\   ", "  (({E})({E}))  ", "  (  ><  )  ", "   .----.   "],
            ["            ", "   /\\  /\\   ", "  (({E})(-))  ", "  (  ><  )  ", "   `----´   "],
        ],
        .penguin: [
            ["            ", "  .---.     ", "  ({E}>{E})     ", " /(   )\\    ", "  `---´     "],
            ["            ", "  .---.     ", "  ({E}>{E})     ", " |(   )|    ", "  `---´     "],
            ["  .---.     ", "  ({E}>{E})     ", " /(   )\\    ", "  `---´     ", "   ~ ~      "],
        ],
        .turtle: [
            ["            ", "   _,--._   ", "  ( {E}  {E} )  ", " /[______]\\ ", "  ``    ``  "],
            ["            ", "   _,--._   ", "  ( {E}  {E} )  ", " /[______]\\ ", "   ``  ``   "],
            ["            ", "   _,--._   ", "  ( {E}  {E} )  ", " /[======]\\ ", "  ``    ``  "],
        ],
        .snail: [
            ["            ", " {E}    .--.  ", "  \\  ( @ )  ", "   \\_`--´   ", "  ~~~~~~~   "],
            ["            ", "  {E}   .--.  ", "  |  ( @ )  ", "   \\_`--´   ", "  ~~~~~~~   "],
            ["            ", " {E}    .--.  ", "  \\  ( @  ) ", "   \\_`--´   ", "   ~~~~~~   "],
        ],
        .ghost: [
            ["            ", "   .----.   ", "  / {E}  {E} \\  ", "  |      |  ", "  ~`~``~`~  "],
            ["            ", "   .----.   ", "  / {E}  {E} \\  ", "  |      |  ", "  `~`~~`~`  "],
            ["    ~  ~    ", "   .----.   ", "  / {E}  {E} \\  ", "  |      |  ", "  ~~`~~`~~  "],
        ],
        .axolotl: [
            ["            ", "}~(______)~{", "}~({E} .. {E})~{", "  ( .--. )  ", "  (_/  \\_)  "],
            ["            ", "~}(______){~", "~}({E} .. {E}){~", "  ( .--. )  ", "  (_/  \\_)  "],
            ["            ", "}~(______)~{", "}~({E} .. {E})~{", "  (  --  )  ", "  ~_/  \\_~  "],
        ],
        .capybara: [
            ["            ", "  n______n  ", " ( {E}    {E} ) ", " (   oo   ) ", "  `------´  "],
            ["            ", "  n______n  ", " ( {E}    {E} ) ", " (   Oo   ) ", "  `------´  "],
            ["    ~  ~    ", "  u______n  ", " ( {E}    {E} ) ", " (   oo   ) ", "  `------´  "],
        ],
        .cactus: [
            ["            ", " n  ____  n ", " | |{E}  {E}| | ", " |_|    |_| ", "   |    |   "],
            ["            ", "    ____    ", " n |{E}  {E}| n ", " |_|    |_| ", "   |    |   "],
            [" n        n ", " |  ____  | ", " | |{E}  {E}| | ", " |_|    |_| ", "   |    |   "],
        ],
        .robot: [
            ["            ", "   .[||].   ", "  [ {E}  {E} ]  ", "  [ ==== ]  ", "  `------´  "],
            ["            ", "   .[||].   ", "  [ {E}  {E} ]  ", "  [ -==- ]  ", "  `------´  "],
            ["     *      ", "   .[||].   ", "  [ {E}  {E} ]  ", "  [ ==== ]  ", "  `------´  "],
        ],
        .rabbit: [
            ["            ", "   (\\__/)   ", "  ( {E}  {E} )  ", " =(  ..  )= ", "  (\")__(\")  "],
            ["            ", "   (|__/)   ", "  ( {E}  {E} )  ", " =(  ..  )= ", "  (\")__(\")  "],
            ["            ", "   (\\__/)   ", "  ( {E}  {E} )  ", " =( .  . )= ", "  (\")__(\")  "],
        ],
        .mushroom: [
            ["            ", " .-o-OO-o-. ", "(__________)", "   |{E}  {E}|   ", "   |____|   "],
            ["            ", " .-O-oo-O-. ", "(__________)", "   |{E}  {E}|   ", "   |____|   "],
            ["   . o  .   ", " .-o-OO-o-. ", "(__________)", "   |{E}  {E}|   ", "   |____|   "],
        ],
        .chonk: [
            ["            ", "  /\\    /\\  ", " ( {E}    {E} ) ", " (   ..   ) ", "  `------´  "],
            ["            ", "  /\\    /|  ", " ( {E}    {E} ) ", " (   ..   ) ", "  `------´  "],
            ["            ", "  /\\    /\\  ", " ( {E}    {E} ) ", " (   ..   ) ", "  `------´~ "],
        ],
    ]

    static let hatLines: [BuddyHat: String] = [
        .none: "",
        .crown: "   \\^^^/    ",
        .tophat: "   [___]    ",
        .propeller: "    -+-     ",
        .halo: "   (   )    ",
        .wizard: "    /^\\     ",
        .beanie: "   (___)    ",
        .tinyduck: "    ,>      ",
    ]

    static func face(species: BuddySpecies, eye: BuddyEye) -> String {
        let value = eye.rawValue
        switch species {
        case .duck, .goose:
            return "(\(value)>"
        case .blob:
            return "(\(value)\(value))"
        case .cat:
            return "=\(value)ω\(value)="
        case .dragon:
            return "<\(value)~\(value)>"
        case .octopus:
            return "~(\(value)\(value))~"
        case .owl:
            return "(\(value))(\(value))"
        case .penguin:
            return "(\(value)>)"
        case .turtle:
            return "[\(value)_\(value)]"
        case .snail:
            return "\(value)(@)"
        case .ghost:
            return "/\(value)\(value)\\"
        case .axolotl:
            return "}\(value).\(value){"
        case .capybara:
            return "(\(value)oo\(value))"
        case .cactus:
            return "|\(value)  \(value)|"
        case .robot:
            return "[\(value)\(value)]"
        case .rabbit:
            return "(\(value)..\(value))"
        case .mushroom:
            return "|\(value)  \(value)|"
        case .chonk:
            return "(\(value).\(value))"
        }
    }

    static func renderFrame(species: BuddySpecies, eye: BuddyEye, hat: BuddyHat, frame: Int) -> [String] {
        guard let frames = bodies[species], !frames.isEmpty else {
            return []
        }

        let normalized = frame % frames.count
        let body = frames[normalized].map { $0.replacingOccurrences(of: "{E}", with: eye.rawValue) }
        var lines = body

        if hat != .none, lines.first?.isBlankLine == true {
            lines[0] = hatLines[hat] ?? ""
        }

        if lines.first?.isBlankLine == true, frames.allSatisfy({ ($0.first ?? "").isBlankLine }) {
            lines.removeFirst()
        }

        return lines
    }
}

private extension String {
    var isBlankLine: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
