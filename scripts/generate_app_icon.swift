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

guard CommandLine.arguments.count == 3 else {
    FileHandle.standardError.write(Data("Usage: swift scripts/generate_app_icon.swift <source.png> <output.iconset>\n".utf8))
    exit(64)
}

let sourceURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])

guard let sourceImage = NSImage(contentsOf: sourceURL) else {
    FileHandle.standardError.write(Data("Unable to read logo source: \(sourceURL.path)\n".utf8))
    exit(66)
}

try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

for spec in specs {
    let image = resizedImage(from: sourceImage, pixelSize: spec.pixels)
    try pngData(from: image).write(to: outputURL.appendingPathComponent(spec.filename))
}

private func resizedImage(from source: NSImage, pixelSize: Int) -> NSImage {
    let size = NSSize(width: pixelSize, height: pixelSize)
    let image = NSImage(size: size)

    image.lockFocus()
    defer {
        image.unlockFocus()
    }

    NSGraphicsContext.current?.imageInterpolation = .high
    NSColor.clear.setFill()
    NSRect(origin: .zero, size: size).fill()
    source.draw(
        in: NSRect(origin: .zero, size: size),
        from: NSRect(origin: .zero, size: source.size),
        operation: .sourceOver,
        fraction: 1
    )

    return image
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
