import AppKit
import Foundation

struct IconSpec {
    let filename: String
    let pixels: Int
}

let specs = [
    IconSpec(filename: "icon_16x16.png", pixels: 16),
    IconSpec(filename: "icon_16x16@2x.png", pixels: 32),
    IconSpec(filename: "icon_32x32.png", pixels: 32),
    IconSpec(filename: "icon_32x32@2x.png", pixels: 64),
    IconSpec(filename: "icon_128x128.png", pixels: 128),
    IconSpec(filename: "icon_128x128@2x.png", pixels: 256),
    IconSpec(filename: "icon_256x256.png", pixels: 256),
    IconSpec(filename: "icon_256x256@2x.png", pixels: 512),
    IconSpec(filename: "icon_512x512.png", pixels: 512),
    IconSpec(filename: "icon_512x512@2x.png", pixels: 1024)
]

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("Usage: swift scripts/generate_app_icon.swift <output.iconset>\n".utf8))
    exit(64)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

for spec in specs {
    let image = drawIcon(pixelSize: spec.pixels)
    let destination = outputURL.appendingPathComponent(spec.filename)
    try pngData(from: image).write(to: destination)
}

private func drawIcon(pixelSize: Int) -> NSImage {
    let size = NSSize(width: pixelSize, height: pixelSize)
    let image = NSImage(size: size)
    image.lockFocus()
    defer {
        image.unlockFocus()
    }

    let scale = CGFloat(pixelSize) / 1024
    func r(_ value: CGFloat) -> CGFloat { value * scale }

    let canvas = NSRect(origin: .zero, size: size)
    NSColor.clear.setFill()
    canvas.fill()

    let plate = NSBezierPath(roundedRect: canvas.insetBy(dx: r(68), dy: r(68)), xRadius: r(210), yRadius: r(210))
    plate.addClip()

    let background = NSGradient(colors: [
        NSColor(calibratedRed: 0.02, green: 0.08, blue: 0.12, alpha: 1),
        NSColor(calibratedRed: 0.08, green: 0.24, blue: 0.32, alpha: 1)
    ])
    background?.draw(in: canvas, angle: 90)

    NSColor(calibratedRed: 0.08, green: 0.78, blue: 1.0, alpha: 0.16).setStroke()
    for step in stride(from: r(128), through: r(896), by: r(96)) {
        let vertical = NSBezierPath()
        vertical.move(to: NSPoint(x: step, y: r(84)))
        vertical.line(to: NSPoint(x: step, y: r(940)))
        vertical.lineWidth = max(1, r(4))
        vertical.stroke()

        let horizontal = NSBezierPath()
        horizontal.move(to: NSPoint(x: r(84), y: step))
        horizontal.line(to: NSPoint(x: r(940), y: step))
        horizontal.lineWidth = max(1, r(4))
        horizontal.stroke()
    }

    let shadow = NSBezierPath(ovalIn: NSRect(x: r(170), y: r(196), width: r(684), height: r(132)))
    NSColor.black.withAlphaComponent(0.32).setFill()
    shadow.fill()

    drawTread(x: r(218), y: r(302), width: r(142), height: r(350), radius: r(44), scale: scale)
    drawTread(x: r(664), y: r(302), width: r(142), height: r(350), radius: r(44), scale: scale)

    let hull = NSBezierPath(roundedRect: NSRect(x: r(305), y: r(318), width: r(414), height: r(318)), xRadius: r(74), yRadius: r(74))
    NSColor(calibratedRed: 0.08, green: 0.42, blue: 0.94, alpha: 1).setFill()
    hull.fill()
    NSColor(calibratedRed: 0.76, green: 0.92, blue: 1.0, alpha: 1).setStroke()
    hull.lineWidth = r(20)
    hull.stroke()

    let highlight = NSBezierPath(roundedRect: NSRect(x: r(370), y: r(520), width: r(284), height: r(42)), xRadius: r(20), yRadius: r(20))
    NSColor.white.withAlphaComponent(0.26).setFill()
    highlight.fill()

    let turretBase = NSBezierPath(ovalIn: NSRect(x: r(374), y: r(424), width: r(276), height: r(276)))
    NSColor(calibratedRed: 0.02, green: 0.12, blue: 0.26, alpha: 1).setFill()
    turretBase.fill()

    let turret = NSBezierPath(ovalIn: NSRect(x: r(408), y: r(458), width: r(208), height: r(208)))
    NSColor(calibratedRed: 0.12, green: 0.65, blue: 1.0, alpha: 1).setFill()
    turret.fill()
    NSColor(calibratedRed: 0.76, green: 0.92, blue: 1.0, alpha: 1).setStroke()
    turret.lineWidth = r(12)
    turret.stroke()

    let barrel = NSBezierPath(roundedRect: NSRect(x: r(474), y: r(620), width: r(76), height: r(250)), xRadius: r(26), yRadius: r(26))
    NSColor(calibratedRed: 0.06, green: 0.28, blue: 0.70, alpha: 1).setFill()
    barrel.fill()
    NSColor(calibratedRed: 0.02, green: 0.10, blue: 0.22, alpha: 1).setStroke()
    barrel.lineWidth = r(12)
    barrel.stroke()

    let muzzle = NSBezierPath(roundedRect: NSRect(x: r(438), y: r(836), width: r(148), height: r(54)), xRadius: r(22), yRadius: r(22))
    NSColor(calibratedRed: 0.02, green: 0.10, blue: 0.22, alpha: 1).setFill()
    muzzle.fill()

    let hatch = NSBezierPath(ovalIn: NSRect(x: r(448), y: r(520), width: r(74), height: r(74)))
    NSColor(calibratedRed: 0.02, green: 0.10, blue: 0.22, alpha: 0.88).setFill()
    hatch.fill()

    let flagPole = NSBezierPath()
    flagPole.move(to: NSPoint(x: r(650), y: r(596)))
    flagPole.line(to: NSPoint(x: r(650), y: r(790)))
    NSColor(calibratedRed: 0.76, green: 0.92, blue: 1.0, alpha: 1).setStroke()
    flagPole.lineWidth = r(12)
    flagPole.stroke()

    let flag = NSBezierPath()
    flag.move(to: NSPoint(x: r(650), y: r(790)))
    flag.line(to: NSPoint(x: r(794), y: r(736)))
    flag.line(to: NSPoint(x: r(650), y: r(682)))
    flag.close()
    NSColor(calibratedRed: 1.0, green: 0.24, blue: 0.30, alpha: 1).setFill()
    flag.fill()

    plate.lineWidth = r(18)
    NSColor.white.withAlphaComponent(0.14).setStroke()
    plate.stroke()

    return image
}

private func drawTread(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, radius: CGFloat, scale: CGFloat) {
    let tread = NSBezierPath(roundedRect: NSRect(x: x, y: y, width: width, height: height), xRadius: radius, yRadius: radius)
    NSColor(calibratedRed: 0.03, green: 0.06, blue: 0.10, alpha: 1).setFill()
    tread.fill()

    for treadY in stride(from: y + height * 0.14, through: y + height * 0.86, by: height * 0.16) {
        let plate = NSBezierPath(roundedRect: NSRect(x: x + width * 0.18, y: treadY, width: width * 0.64, height: max(2, 10 * scale)), xRadius: 3 * scale, yRadius: 3 * scale)
        NSColor.white.withAlphaComponent(0.20).setFill()
        plate.fill()
    }
}

private func pngData(from image: NSImage) throws -> Data {
    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let png = bitmap.representation(using: .png, properties: [:])
    else {
        throw CocoaError(.fileWriteUnknown)
    }

    return png
}
