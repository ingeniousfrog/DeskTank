import AppKit

enum AppIconFactory {
    static func menuBarIcon() -> NSImage {
        if let bundledIcon = bundledAppIcon() {
            bundledIcon.size = NSSize(width: 18, height: 18)
            bundledIcon.isTemplate = false
            return bundledIcon
        }

        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()
        defer {
            image.unlockFocus()
        }

        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()

        NSColor.black.withAlphaComponent(0.24).setFill()
        NSBezierPath(ovalIn: NSRect(x: 2.5, y: 2.2, width: 13, height: 3.2)).fill()

        let tread = NSBezierPath(roundedRect: NSRect(x: 2.4, y: 4.2, width: 13.2, height: 5.2), xRadius: 2.2, yRadius: 2.2)
        NSColor(calibratedRed: 0.04, green: 0.07, blue: 0.11, alpha: 1).setFill()
        tread.fill()

        let hull = NSBezierPath()
        hull.move(to: NSPoint(x: 3.2, y: 8.6))
        hull.curve(to: NSPoint(x: 14.7, y: 8.5), controlPoint1: NSPoint(x: 5.0, y: 12.0), controlPoint2: NSPoint(x: 12.8, y: 12.0))
        hull.line(to: NSPoint(x: 13.4, y: 5.0))
        hull.line(to: NSPoint(x: 4.2, y: 5.0))
        hull.close()
        NSColor(calibratedRed: 0.10, green: 0.47, blue: 0.96, alpha: 1).setFill()
        hull.fill()
        NSColor(calibratedRed: 0.78, green: 0.94, blue: 1.0, alpha: 1).setStroke()
        hull.lineWidth = 0.8
        hull.stroke()

        let turret = NSBezierPath(roundedRect: NSRect(x: 6.4, y: 8.2, width: 6.4, height: 4.6), xRadius: 1.8, yRadius: 1.8)
        NSColor(calibratedRed: 0.30, green: 0.76, blue: 1.0, alpha: 1).setFill()
        turret.fill()

        let barrel = NSBezierPath(roundedRect: NSRect(x: 11.8, y: 9.7, width: 4.5, height: 1.1), xRadius: 0.5, yRadius: 0.5)
        NSColor(calibratedRed: 0.05, green: 0.21, blue: 0.55, alpha: 1).setFill()
        barrel.fill()

        let eye = NSBezierPath(ovalIn: NSRect(x: 7.4, y: 9.2, width: 1.2, height: 1.2))
        NSColor(calibratedRed: 0.03, green: 0.14, blue: 0.30, alpha: 1).setFill()
        eye.fill()

        let smile = NSBezierPath()
        smile.move(to: NSPoint(x: 8.7, y: 8.8))
        smile.curve(to: NSPoint(x: 11.0, y: 8.8), controlPoint1: NSPoint(x: 9.2, y: 8.0), controlPoint2: NSPoint(x: 10.5, y: 8.0))
        NSColor(calibratedRed: 0.03, green: 0.14, blue: 0.30, alpha: 1).setStroke()
        smile.lineWidth = 0.6
        smile.stroke()

        let flag = NSBezierPath()
        flag.move(to: NSPoint(x: 13.2, y: 12.6))
        flag.line(to: NSPoint(x: 16.3, y: 11.6))
        flag.line(to: NSPoint(x: 13.2, y: 10.5))
        flag.close()
        NSColor(calibratedRed: 1.0, green: 0.24, blue: 0.30, alpha: 1).setFill()
        flag.fill()

        image.isTemplate = false
        return image
    }

    private static func bundledAppIcon() -> NSImage? {
        guard let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns") else {
            return nil
        }

        return NSImage(contentsOf: url)
    }
}
