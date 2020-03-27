import Cocoa

extension CGFloat {
    var magnitudeOrder: Int {
        var order = 0
        var val = abs(self)
        if val == 0 {
            // do nothing
        } else if val > 1 {
            while val >= 10 {
                val /= 10
                order += 1
            }
        } else {
            while val < 1 {
                val *= 10
                order -= 1
            }
        }

        return order
    }
}
