struct Mulberry32 {
    private var seed: UInt32

    init(seed: UInt32) {
        self.seed = seed
    }

    mutating func next() -> Double {
        var a = Int32(bitPattern: seed)
        // a |= 0 — JS coercion idiom, no-op in Swift Int32
        a = a &+ Int32(bitPattern: 0x6d2b79f5)

        var t = imul(
            a ^ Int32(bitPattern: UInt32(bitPattern: a) >> 15),
            1 | a
        )
        t = (t &+ imul(
            t ^ Int32(bitPattern: UInt32(bitPattern: t) >> 7),
            61 | t
        )) ^ t

        seed = UInt32(bitPattern: a)

        let result = UInt32(bitPattern: t ^ Int32(bitPattern: UInt32(bitPattern: t) >> 14))
        return Double(result) / 4_294_967_296.0
    }

    private func imul(_ lhs: Int32, _ rhs: Int32) -> Int32 {
        lhs &* rhs
    }
}
