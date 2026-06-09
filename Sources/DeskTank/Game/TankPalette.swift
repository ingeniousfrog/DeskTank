import AppKit

struct TankPalette {
    let body: NSColor
    let turret: NSColor
    let barrel: NSColor
    let tread: NSColor
    let trim: NSColor
    let darkStroke: NSColor

    static let player = TankPalette(
        body: NSColor(calibratedRed: 0.08, green: 0.39, blue: 0.92, alpha: 1),
        turret: NSColor(calibratedRed: 0.14, green: 0.62, blue: 1.0, alpha: 1),
        barrel: NSColor(calibratedRed: 0.06, green: 0.26, blue: 0.68, alpha: 1),
        tread: NSColor(calibratedRed: 0.03, green: 0.06, blue: 0.11, alpha: 1),
        trim: NSColor(calibratedRed: 0.75, green: 0.90, blue: 1.0, alpha: 1),
        darkStroke: NSColor(calibratedRed: 0.02, green: 0.08, blue: 0.20, alpha: 1)
    )

    static let enemy = TankPalette(
        body: NSColor(calibratedRed: 0.86, green: 0.09, blue: 0.13, alpha: 1),
        turret: NSColor(calibratedRed: 1.0, green: 0.25, blue: 0.28, alpha: 1),
        barrel: NSColor(calibratedRed: 0.62, green: 0.02, blue: 0.05, alpha: 1),
        tread: NSColor(calibratedRed: 0.10, green: 0.03, blue: 0.03, alpha: 1),
        trim: NSColor(calibratedRed: 1.0, green: 0.74, blue: 0.65, alpha: 1),
        darkStroke: NSColor(calibratedRed: 0.24, green: 0.02, blue: 0.03, alpha: 1)
    )
}
