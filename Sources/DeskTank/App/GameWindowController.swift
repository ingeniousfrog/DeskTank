import AppKit
import SpriteKit

@MainActor
final class GameWindowController {
    private var window: NSWindow?
    private var gameScene: GameScene?
    private var hasStartedGame = false

    var onVisibilityChanged: (() -> Void)?

    var isVisible: Bool {
        window?.isVisible == true
    }

    var primaryActionTitle: String {
        hasStartedGame ? "Resume" : "Start New Game"
    }

    func show() {
        guard let screen = NSScreen.main else {
            return
        }

        if window == nil {
            createWindow(screen: screen)
        }

        refreshFrame(screen: screen)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        gameScene?.start()
        hasStartedGame = true
        onVisibilityChanged?()
    }

    func hide() {
        window?.orderOut(nil)
        gameScene?.pauseGame()
        onVisibilityChanged?()
    }

    func toggle() {
        isVisible ? hide() : show()
    }

    func startNewGame() {
        show()
        gameScene?.startNewGame()
    }

    func resumeGame() {
        show()
    }

    private func createWindow(screen: NSScreen) {
        let window = GameWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true

        let skView = DeskTankView(frame: screen.frame)
        skView.allowsTransparency = true
        skView.ignoresSiblingOrder = true

        let scene = GameScene(size: screen.frame.size) { [weak self] in
            self?.hide()
        }
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)

        window.contentView = skView
        self.window = window
        gameScene = scene
    }

    private func refreshFrame(screen: NSScreen) {
        window?.setFrame(screen.frame, display: true)
        gameScene?.size = screen.frame.size
    }
}

private final class DeskTankView: SKView {
    override var acceptsFirstResponder: Bool {
        true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }
}

private final class GameWindow: NSWindow {
    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }
}
