import AppKit
import DeskTankCore

@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let gameWindowController: GameWindowController
    private let statsStore = GameStatsStore()
    private let titleItem = NSMenuItem()
    private let totalKillsItem = NSMenuItem()
    private let winsItem = NSMenuItem()
    private let lossesItem = NSMenuItem()
    private let winRateItem = NSMenuItem()
    private let primaryActionItem = NSMenuItem()

    init(gameWindowController: GameWindowController) {
        self.gameWindowController = gameWindowController
        super.init()
        setupStatusItem()
        setupMenu()
        refresh()
    }

    func refresh() {
        let stats = statsStore.load()
        let winRate = Int((stats.winRate * 100).rounded())

        titleItem.title = "DeskTank Battle Record"
        totalKillsItem.title = "Total Kills: \(stats.totalKills)"
        winsItem.title = "Successes: \(stats.successes)"
        lossesItem.title = "Failures: \(stats.failures)"
        winRateItem.title = "Win Rate: \(winRate)%"
        primaryActionItem.title = gameWindowController.primaryActionTitle
    }

    func menuWillOpen(_ menu: NSMenu) {
        refresh()
    }

    private func setupStatusItem() {
        statusItem.button?.title = ""
        statusItem.button?.image = AppIconFactory.menuBarIcon()
        statusItem.button?.imagePosition = .imageOnly
        statusItem.button?.toolTip = "DeskTank"
    }

    private func setupMenu() {
        menu.delegate = self
        titleItem.isEnabled = false
        totalKillsItem.isEnabled = false
        winsItem.isEnabled = false
        lossesItem.isEnabled = false
        winRateItem.isEnabled = false

        primaryActionItem.target = self
        primaryActionItem.action = #selector(handlePrimaryAction)

        let quitItem = NSMenuItem(title: "Quit", action: #selector(handleQuit), keyEquivalent: "q")
        quitItem.target = self

        [
            titleItem,
            .separator(),
            totalKillsItem,
            winsItem,
            lossesItem,
            winRateItem,
            .separator(),
            primaryActionItem,
            quitItem
        ].forEach(menu.addItem)

        statusItem.menu = menu
    }

    @objc private func handlePrimaryAction() {
        if gameWindowController.primaryActionTitle == "Start New Game" {
            gameWindowController.startNewGame()
        } else {
            gameWindowController.resumeGame()
        }
        refresh()
    }

    @objc private func handleQuit() {
        NSApp.terminate(nil)
    }
}
