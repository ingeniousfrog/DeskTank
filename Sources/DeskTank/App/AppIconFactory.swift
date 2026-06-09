import AppKit

enum AppIconFactory {
    static func menuBarIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()
        defer {
            image.unlockFocus()
        }

        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()

        let treadColor = NSColor(calibratedRed: 0.08, green: 0.10, blue: 0.12, alpha: 1)
        let bodyColor = NSColor(calibratedRed: 0.10, green: 0.45, blue: 0.95, alpha: 1)
        let trimColor = NSColor(calibratedRed: 0.78, green: 0.94, blue: 1.0, alpha: 1)

        let leftTread = NSBezierPath(roundedRect: NSRect(x: 2.0, y: 4.0, width: 3.2, height: 9.0), xRadius: 1.4, yRadius: 1.4)
        let rightTread = NSBezierPath(roundedRect: NSRect(x: 12.8, y: 4.0, width: 3.2, height: 9.0), xRadius: 1.4, yRadius: 1.4)
        treadColor.setFill()
        leftTread.fill()
        rightTread.fill()

        let hull = NSBezierPath(roundedRect: NSRect(x: 4.5, y: 4.8, width: 9.0, height: 8.0), xRadius: 2.0, yRadius: 2.0)
        bodyColor.setFill()
        hull.fill()
        trimColor.setStroke()
        hull.lineWidth = 0.8
        hull.stroke()

        let turret = NSBezierPath(ovalIn: NSRect(x: 6.4, y: 7.2, width: 5.2, height: 5.2))
        NSColor(calibratedRed: 0.16, green: 0.66, blue: 1.0, alpha: 1).setFill()
        turret.fill()

        let barrel = NSBezierPath(roundedRect: NSRect(x: 8.0, y: 11.0, width: 2.0, height: 5.3), xRadius: 0.8, yRadius: 0.8)
        bodyColor.setFill()
        barrel.fill()

        let flagPole = NSBezierPath()
        flagPole.move(to: NSPoint(x: 12.8, y: 10.4))
        flagPole.line(to: NSPoint(x: 12.8, y: 15.8))
        trimColor.setStroke()
        flagPole.lineWidth = 0.8
        flagPole.stroke()

        let flag = NSBezierPath()
        flag.move(to: NSPoint(x: 12.8, y: 15.8))
        flag.line(to: NSPoint(x: 16.0, y: 14.6))
        flag.line(to: NSPoint(x: 12.8, y: 13.4))
        flag.close()
        NSColor(calibratedRed: 1.0, green: 0.24, blue: 0.30, alpha: 1).setFill()
        flag.fill()

        image.isTemplate = false
        return image
    }
}
