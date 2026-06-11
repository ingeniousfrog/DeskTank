import AppKit
import DeskTankCore
import Foundation

protocol DesktopScanning: Sendable {
    func scan(screenFrame: CGRect) -> [DesktopItem]
}

struct DesktopScanner: DesktopScanning {
    private let iconSize = CGSize(width: 76, height: 88)
    private let fallbackColumnWidth: CGFloat = 96
    private let fallbackRowHeight: CGFloat = 108

    func scan(screenFrame: CGRect) -> [DesktopItem] {
        let desktopURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        let urls = desktopURLs(in: desktopURL)
        let appleScriptFrames = finderDesktopPositions(screenFrame: screenFrame)

        return urls.enumerated().map { index, url in
            let id = url.path
            let name = url.lastPathComponent
            let resourceValues = try? url.resourceValues(forKeys: [.isDirectoryKey])
            let frame = appleScriptFrames[name] ?? fallbackFrame(index: index, screenFrame: screenFrame)
            return DesktopItem(
                id: id,
                name: name,
                frame: frame.toCoreRect(screenHeight: screenFrame.height),
                isDirectory: resourceValues?.isDirectory == true
            )
        }
    }

    private func desktopURLs(in desktopURL: URL) -> [URL] {
        do {
            return try FileManager.default.contentsOfDirectory(
                at: desktopURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
        } catch {
            NSLog("DeskTank failed to read Desktop directory: \(error.localizedDescription)")
            return []
        }
    }

    private func fallbackFrame(index: Int, screenFrame: CGRect) -> CGRect {
        let usableHeight = max(fallbackRowHeight, screenFrame.height - 80)
        let rows = max(1, Int(usableHeight / fallbackRowHeight))
        let column = index / rows
        let row = index % rows
        let x = screenFrame.maxX - CGFloat(column + 1) * fallbackColumnWidth
        let y = screenFrame.minY + 40 + CGFloat(row) * fallbackRowHeight

        return CGRect(origin: CGPoint(x: x, y: y), size: iconSize)
    }

    private func finderDesktopPositions(screenFrame: CGRect) -> [String: CGRect] {
        let script = """
        tell application "Finder"
            set outputLines to {}
            set desktopCount to count of items of desktop
            repeat with i from 1 to desktopCount
                try
                    set desktopItem to item i of desktop
                    set itemName to name of desktopItem as text
                    set itemPosition to desktop position of desktopItem
                    set xPos to item 1 of itemPosition
                    set yPos to item 2 of itemPosition
                    set end of outputLines to itemName & "\t" & xPos & "\t" & yPos
                end try
            end repeat
            set AppleScript's text item delimiters to "\n"
            set outputText to outputLines as text
            set AppleScript's text item delimiters to ""
            return outputText
        end tell
        """

        var error: NSDictionary?
        guard let rawOutput = NSAppleScript(source: script)?.executeAndReturnError(&error).stringValue else {
            if let error {
                NSLog("DeskTank Finder desktop position lookup failed: \(error)")
            }
            return [:]
        }

        return rawOutput
            .split(separator: "\n")
            .reduce(into: [String: CGRect]()) { result, line in
                let parts = line.split(separator: "\t", omittingEmptySubsequences: false)
                guard parts.count == 3,
                      let x = Double(parts[1]),
                      let y = Double(parts[2]) else {
                    return
                }

                let name = String(parts[0])
                result[name] = CGRect(
                    origin: CGPoint(
                        x: CGFloat(x) - iconSize.width / 2,
                        y: CGFloat(y) - iconSize.height / 2
                    ),
                    size: iconSize
                ).offsetBy(dx: screenFrame.minX, dy: screenFrame.minY)
            }
    }
}

private extension CGRect {
    func toCoreRect(screenHeight: CGFloat) -> Rect {
        Rect(
            origin: Point(x: minX, y: screenHeight - maxY),
            size: Size(width: width, height: height)
        )
    }
}
