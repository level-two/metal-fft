extension Int {
    func binaryInversed(numberOfDigits: Int) -> Int {
        var value = self
        var result = 0
        for _ in 0 ..< numberOfDigits {
            result = (result << 1) | (value & 0x1)
            value = value >> 1
        }
        return result
    }
}
