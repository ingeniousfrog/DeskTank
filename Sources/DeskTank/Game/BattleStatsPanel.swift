import AppKit
import DeskTankCore
import SpriteKit

@MainActor
final class BattleStatsPanel: SKNode {
    private let background = SKShapeNode()
    private let glow = SKShapeNode()
    private let title = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let statusLine = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let recordNodes = (0..<4).map { _ in StatReadoutNode() }
    private let controlLines = (0..<3).map { _ in SKLabelNode(fontNamed: "AvenirNext-Medium") }
    private let panelSize = CGSize(width: 430, height: 188)

    override init() {
        super.init()
        zPosition = 900
        setupChrome()
        setupText()
        setupReadouts()
    }

    required init?(coder aDecoder: NSCoder) {
        nil
    }

    func update(
        phase: GamePhase,
        enemiesRemaining: Int,
        fortressHealth: Int,
        stats: GameStats,
        sceneSize: CGSize
    ) {
        position = CGPoint(x: 18, y: sceneSize.height - panelSize.height - 18)
        background.path = panelPath
        glow.path = panelPath

        title.text = "DESKTANK OPS"
        statusLine.text = "\(phase.displayName)  |  ENEMIES \(enemiesRemaining)  |  BASE HP \(fortressHealth)"

        let winRate = Int((stats.winRate * 100).rounded())
        let readouts = [
            ("KILLS", "\(stats.totalKills)", NSColor(calibratedRed: 0.08, green: 0.78, blue: 1.0, alpha: 1)),
            ("RUN", "\(stats.currentRunKills)", NSColor(calibratedRed: 0.42, green: 1.0, blue: 0.55, alpha: 1)),
            ("WINS", "\(stats.successes)", NSColor(calibratedRed: 1.0, green: 0.82, blue: 0.24, alpha: 1)),
            ("LOSSES", "\(stats.failures)", NSColor(calibratedRed: 1.0, green: 0.25, blue: 0.30, alpha: 1))
        ]

        zip(recordNodes, readouts).enumerated().forEach { index, pair in
            let (node, readout) = pair
            node.update(label: readout.0, value: readout.1, accent: readout.2)
            node.position = CGPoint(x: 18 + CGFloat(index) * 100, y: 74)
        }

        let controls = [
            "BLUE=P1   RED=CPU   YELLOW=BASE   WIN RATE \(winRate)%",
            "WASD MOVE    J FIRE    SPACE PAUSE",
            "R RESTART    ESC/Q QUIT    CMD+OPT+T HIDE"
        ]

        zip(controlLines, controls).enumerated().forEach { index, pair in
            let (line, text) = pair
            line.text = text
            line.position = CGPoint(x: 18, y: 50 - CGFloat(index) * 17)
        }
    }

    private var panelPath: CGPath {
        CGPath(
            roundedRect: CGRect(origin: .zero, size: panelSize),
            cornerWidth: 12,
            cornerHeight: 12,
            transform: nil
        )
    }

    private func setupChrome() {
        glow.fillColor = .clear
        glow.strokeColor = NSColor(calibratedRed: 0.12, green: 0.75, blue: 1.0, alpha: 0.50)
        glow.lineWidth = 5
        glow.alpha = 0.55
        addChild(glow)

        background.fillColor = NSColor(calibratedRed: 0.02, green: 0.04, blue: 0.06, alpha: 0.78)
        background.strokeColor = NSColor(calibratedRed: 0.55, green: 0.92, blue: 1.0, alpha: 0.62)
        background.lineWidth = 1.5
        addChild(background)

        let scanlinePath = CGMutablePath()
        stride(from: 12.0, through: panelSize.height - 12, by: 9).forEach { y in
            scanlinePath.move(to: CGPoint(x: 12, y: y))
            scanlinePath.addLine(to: CGPoint(x: panelSize.width - 12, y: y))
        }
        let scanlines = SKShapeNode(path: scanlinePath)
        scanlines.strokeColor = NSColor.white.withAlphaComponent(0.035)
        scanlines.lineWidth = 1
        addChild(scanlines)
    }

    private func setupText() {
        title.fontSize = 17
        title.fontColor = NSColor(calibratedRed: 0.76, green: 0.96, blue: 1.0, alpha: 1)
        title.horizontalAlignmentMode = .left
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: 18, y: 164)
        addChild(title)

        statusLine.fontSize = 11
        statusLine.fontColor = NSColor.white.withAlphaComponent(0.78)
        statusLine.horizontalAlignmentMode = .left
        statusLine.verticalAlignmentMode = .center
        statusLine.position = CGPoint(x: 18, y: 143)
        addChild(statusLine)

        controlLines.forEach { line in
            line.fontSize = 10
            line.fontColor = NSColor.white.withAlphaComponent(0.78)
            line.horizontalAlignmentMode = .left
            line.verticalAlignmentMode = .center
            addChild(line)
        }
    }

    private func setupReadouts() {
        recordNodes.forEach(addChild)
    }
}

@MainActor
private final class StatReadoutNode: SKNode {
    private let capsule = SKShapeNode(rectOf: CGSize(width: 88, height: 48), cornerRadius: 8)
    private let valueLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let labelNode = SKLabelNode(fontNamed: "AvenirNext-DemiBold")

    override init() {
        super.init()
        addChild(capsule)
        addChild(valueLabel)
        addChild(labelNode)

        capsule.lineWidth = 1.3
        capsule.position = CGPoint(x: 44, y: 24)

        valueLabel.fontSize = 22
        valueLabel.horizontalAlignmentMode = .center
        valueLabel.verticalAlignmentMode = .center
        valueLabel.position = CGPoint(x: 44, y: 30)

        labelNode.fontSize = 8
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        labelNode.position = CGPoint(x: 44, y: 11)
    }

    required init?(coder aDecoder: NSCoder) {
        nil
    }

    func update(label: String, value: String, accent: NSColor) {
        capsule.fillColor = accent.withAlphaComponent(0.12)
        capsule.strokeColor = accent.withAlphaComponent(0.86)
        valueLabel.text = value
        valueLabel.fontColor = accent
        labelNode.text = label
        labelNode.fontColor = NSColor.white.withAlphaComponent(0.70)
    }
}

private extension GamePhase {
    var displayName: String {
        switch self {
        case .ready: "READY"
        case .running: "LIVE"
        case .paused: "PAUSED"
        case .won: "VICTORY"
        case .lost: "FAILED"
        }
    }
}
