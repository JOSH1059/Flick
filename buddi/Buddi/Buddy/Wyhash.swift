import Foundation

enum Wyhash {
    private static let secret: [UInt64] = [
        0xa0761d6478bd642f,
        0xe7037ed1a0b428db,
        0x8ebc6af09c88c6e3,
        0x589965cc75374cc3,
    ]

    static func hash(seed: UInt64 = 0, key: String) -> UInt64 {
        sum64(seed: seed, input: Array(key.utf8))
    }

    private static func read(_ data: [UInt8], offset: Int, bytes: Int) -> UInt64 {
        guard bytes > 0, offset < data.count else {
            return 0
        }

        var result: UInt64 = 0
        for i in 0 ..< bytes {
            let index = offset + i
            guard index < data.count else {
                break
            }
            result |= UInt64(data[index]) << UInt64(i * 8)
        }
        return result
    }

    private static func mum(_ a: UInt64, _ b: UInt64) -> (UInt64, UInt64) {
        let product = a.multipliedFullWidth(by: b)
        return (product.low, product.high)
    }

    private static func mix(_ a: UInt64, _ b: UInt64) -> UInt64 {
        let (aMul, bMul) = mum(a, b)
        return aMul ^ bMul
    }

    private static func sum64(seed: UInt64, input: [UInt8]) -> UInt64 {
        var a: UInt64
        var b: UInt64
        var state0 = seed ^ mix(seed ^ secret[0], secret[1])
        let len = input.count

        if len <= 16 {
            if len >= 4 {
                let end = len - 4
                let quarter = (len >> 3) << 2
                a = (read(input, offset: 0, bytes: 4) << 32) | read(input, offset: quarter, bytes: 4)
                b = (read(input, offset: end, bytes: 4) << 32) | read(input, offset: end - quarter, bytes: 4)
            } else if len > 0 {
                a = (UInt64(input[0]) << 16) | (UInt64(input[len >> 1]) << 8) | UInt64(input[len - 1])
                b = 0
            } else {
                a = 0
                b = 0
            }
        } else {
            var state = [state0, state0, state0]
            var i = 0

            if len >= 48 {
                while i + 48 < len {
                    for j in 0 ..< 3 {
                        let aRound = read(input, offset: i + 8 * (2 * j), bytes: 8)
                        let bRound = read(input, offset: i + 8 * (2 * j + 1), bytes: 8)
                        state[j] = mix(aRound ^ secret[j + 1], bRound ^ state[j])
                    }
                    i += 48
                }
                state[0] ^= state[1] ^ state[2]
            }

            let remaining = Array(input[i...])
            var k = 0
            while k + 16 < remaining.count {
                state[0] = mix(
                    read(remaining, offset: k, bytes: 8) ^ secret[1],
                    read(remaining, offset: k + 8, bytes: 8) ^ state[0]
                )
                k += 16
            }

            a = read(input, offset: len - 16, bytes: 8)
            b = read(input, offset: len - 8, bytes: 8)
            state0 = state[0]
        }

        a ^= secret[1]
        b ^= state0
        let (aM, bM) = mum(a, b)
        return mix(aM ^ secret[0] ^ UInt64(len), bM ^ secret[1])
    }
}
