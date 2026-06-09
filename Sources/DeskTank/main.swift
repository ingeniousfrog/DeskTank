import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let gameWindowController = GameWindowController()
    private var hotKeyController: HotKeyController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        hotKeyController = HotKeyController { [weak self] in
            self?.gameWindowController.toggle()
        }
        hotKeyController?.register()
        gameWindowController.show()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyController?.unregister()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
