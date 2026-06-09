import AppKit
import DeskTankCore
import SpriteKit

@MainActor
final class GameScene: SKScene {
    private let scanner: DesktopScanning
    private let rules = GameRules()
    private var watcher: DesktopWatcher?
    private var map: MapModel
    private var phase: GamePhase = .ready
    private var player: Tank
    private var fortress: Fortress
    private var enemies: [Tank] = []
    private var bullets: [Bullet] = []
    private var pressedDirections = Set<Direction>()
    private var lastUpdateTime: TimeInterval?
    private var nextEnemyTurnAt: [String: TimeInterval] = [:]
    private var nextEnemyFireAt: [String: TimeInterval] = [:]
    private var nodesByID: [String: SKNode] = [:]
    private let overlayNode = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let hudNode = SKNode()
    private let hudBackground = SKShapeNode()
    private let hudLines = (0..<5).map { _ in SKLabelNode(fontNamed: "AvenirNext-Medium") }

    init(size: CGSize, scanner: DesktopScanning = DesktopScanner()) {
        self.scanner = scanner
        let bounds = Rect(origin: Point(x: 0, y: 0), size: Size(width: size.width, height: size.height))
        map = MapModel(bounds: bounds)
        player = Tank(
            id: "player",
            frame: Rect(origin: Point(x: 80, y: 80), size: Size(width: 42, height: 42)),
            direction: .up,
            isPlayer: true
        )
        fortress = Fortress(
            frame: Rect(origin: Point(x: size.width / 2 - 28, y: 60), size: Size(width: 56, height: 56)),
            health: 3
        )
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        nil
    }

    override func didMove(to view: SKView) {
        backgroundColor = NSColor.black.withAlphaComponent(0.16)
        view.window?.makeFirstResponder(view)
        setupOverlay()
        setupHUD()
        reloadDesktopMap()
        resetBattle()
        watcher = DesktopWatcher { [weak self] in
            self?.reloadDesktopMap()
        }
        watcher?.start()
    }

    func start() {
        phase = phase == .ready ? .running : phase
        overlayNode.isHidden = phase == .running
        updateHUD()
    }

    func pauseGame() {
        phase = .paused
        updateOverlay("Paused")
    }

    override func keyDown(with event: NSEvent) {
        guard !event.isARepeat else {
            return
        }

        switch event.charactersIgnoringModifiers?.lowercased() {
        case "w":
            pressedDirections.insert(.up)
        case "a":
            pressedDirections.insert(.left)
        case "s":
            pressedDirections.insert(.down)
        case "d":
            pressedDirections.insert(.right)
        case "j":
            firePlayerBullet()
        case " ":
            togglePause()
        case "r":
            resetBattle()
        case "q":
            NSApp.terminate(nil)
        default:
            break
        }

        if event.keyCode == 53 {
            NSApp.terminate(nil)
        }
    }

    override func keyUp(with event: NSEvent) {
        switch event.charactersIgnoringModifiers?.lowercased() {
        case "w":
            pressedDirections.remove(.up)
        case "a":
            pressedDirections.remove(.left)
        case "s":
            pressedDirections.remove(.down)
        case "d":
            pressedDirections.remove(.right)
        default:
            break
        }
    }

    override func update(_ currentTime: TimeInterval) {
        defer {
            lastUpdateTime = currentTime
        }

        guard phase == .running else {
            return
        }

        let deltaTime = min(1.0 / 20.0, currentTime - (lastUpdateTime ?? currentTime))
        updatePlayer(deltaTime: deltaTime)
        updateEnemies(currentTime: currentTime, deltaTime: deltaTime)
        updateBullets(deltaTime: deltaTime)
        render()
    }

    private func reloadDesktopMap() {
        let bounds = Rect(origin: Point(x: 0, y: 0), size: Size(width: size.width, height: size.height))
        let items = scanner.scan(screenFrame: CGRect(origin: .zero, size: size))
        map = MapModel(bounds: bounds).replacingDesktopItems(items)
        player = Tank(
            id: player.id,
            frame: map.nearestOpenFrame(to: player.frame),
            direction: player.direction,
            isPlayer: true,
            reloadRemaining: player.reloadRemaining
        )
        fortress = Fortress(frame: map.nearestOpenFrame(to: fortress.frame), health: fortress.health)
        enemies = enemies.map {
            Tank(
                id: $0.id,
                frame: map.nearestOpenFrame(to: $0.frame),
                direction: $0.direction,
                isPlayer: false,
                reloadRemaining: $0.reloadRemaining
            )
        }
        render()
    }

    private func resetBattle() {
        let tankSize = Size(width: 42, height: 42)
        let baseSize = Size(width: 56, height: 56)
        let playerFrame = map.firstOpenFrame(size: tankSize, preferred: spawnPoints(edge: .bottom)) ??
            Rect(origin: Point(x: 80, y: 80), size: tankSize)
        let baseFrame = map.firstOpenFrame(size: baseSize, preferred: spawnPoints(edge: .center)) ??
            Rect(origin: Point(x: size.width / 2 - 28, y: 60), size: baseSize)
        let enemyFrames = spawnPoints(edge: .top)
            .map { Rect(origin: $0, size: tankSize) }
            .filter { !map.isBlocked($0) && !$0.intersects(playerFrame) && !$0.intersects(baseFrame) }
            .prefix(5)

        player = Tank(id: "player", frame: playerFrame, direction: .up, isPlayer: true)
        fortress = Fortress(frame: baseFrame, health: 3)
        enemies = enemyFrames.enumerated().map { index, frame in
            Tank(id: "enemy-\(index)", frame: frame, direction: [.down, .left, .right][index % 3], isPlayer: false)
        }
        bullets = []
        nextEnemyTurnAt = [:]
        nextEnemyFireAt = [:]
        phase = .running
        overlayNode.isHidden = true
        render()
    }

    private enum SpawnEdge {
        case top
        case bottom
        case center
    }

    private func spawnPoints(edge: SpawnEdge) -> [Point] {
        let columns = stride(from: 40.0, through: max(40, size.width - 80), by: 92).map { $0 }
        let rows: [Double] = switch edge {
        case .top:
            stride(from: max(80, size.height - 140), through: max(80, size.height - 60), by: 70).map { $0 }
        case .bottom:
            stride(from: 60.0, through: 150.0, by: 70).map { $0 }
        case .center:
            stride(from: max(80, size.height / 2 - 90), through: min(size.height - 80, size.height / 2 + 90), by: 70).map { $0 }
        }

        return rows.flatMap { y in columns.map { Point(x: $0, y: y) } }.shuffled()
    }

    private func updatePlayer(deltaTime: Double) {
        guard let direction = pressedDirections.first else {
            player = Tank(
                id: player.id,
                frame: player.frame,
                direction: player.direction,
                isPlayer: true,
                reloadRemaining: max(0, player.reloadRemaining - deltaTime)
            )
            return
        }

        player = rules.movedTank(player, direction: direction, deltaTime: deltaTime, map: map)
    }

    private func updateEnemies(currentTime: TimeInterval, deltaTime: Double) {
        enemies = enemies.map { enemy in
            let direction = enemyDirection(enemy, currentTime: currentTime)
            let moved = rules.movedTank(enemy, direction: direction, deltaTime: deltaTime * 0.68, map: map)
            if currentTime >= nextEnemyFireAt[enemy.id, default: 0] {
                nextEnemyFireAt[enemy.id] = currentTime + rules.enemyFireInterval
                if let bullet = rules.firedBullet(from: moved, bulletID: UUID().uuidString) {
                    bullets.append(bullet)
                }
            }
            return moved
        }
    }

    private func enemyDirection(_ enemy: Tank, currentTime: TimeInterval) -> Direction {
        if currentTime < nextEnemyTurnAt[enemy.id, default: 0] {
            return enemy.direction
        }

        let options: [Direction] = [.down, .left, .right, .up]
        nextEnemyTurnAt[enemy.id] = currentTime + Double.random(in: 0.35...1.1)
        return options.randomElement() ?? .down
    }

    private func updateBullets(deltaTime: Double) {
        let movedBullets = bullets.map { rules.movedBullet($0, deltaTime: deltaTime) }
        var remainingBullets: [Bullet] = []
        var remainingEnemies = enemies
        var nextFortress = fortress
        var nextPhase = phase

        for bullet in movedBullets {
            if map.isBlocked(bullet.frame) {
                continue
            }

            if bullet.ownerID != player.id, bullet.frame.intersects(player.frame) {
                nextPhase = .lost
                continue
            }

            if bullet.frame.intersects(nextFortress.frame) {
                nextFortress = Fortress(frame: nextFortress.frame, health: nextFortress.health - 1)
                if nextFortress.health <= 0 {
                    nextPhase = .lost
                }
                continue
            }

            if bullet.ownerID == player.id,
               let enemyIndex = remainingEnemies.firstIndex(where: { $0.frame.intersects(bullet.frame) }) {
                remainingEnemies.remove(at: enemyIndex)
                continue
            }

            if !map.bounds.contains(bullet.frame) {
                continue
            }

            remainingBullets.append(bullet)
        }

        bullets = remainingBullets
        enemies = remainingEnemies
        fortress = nextFortress

        if enemies.isEmpty, nextPhase == .running {
            nextPhase = .won
        }
        phase = nextPhase

        switch phase {
        case .won:
            updateOverlay("Victory - R to restart")
        case .lost:
            updateOverlay("Base destroyed - R to restart")
        default:
            break
        }
    }

    private func firePlayerBullet() {
        guard phase == .running,
              let bullet = rules.firedBullet(from: player, bulletID: UUID().uuidString) else {
            return
        }

        bullets.append(bullet)
        player = Tank(
            id: player.id,
            frame: player.frame,
            direction: player.direction,
            isPlayer: true,
            reloadRemaining: rules.reloadDuration
        )
    }

    private func togglePause() {
        switch phase {
        case .running:
            phase = .paused
            updateOverlay("Paused")
        case .paused, .ready:
            phase = .running
            overlayNode.isHidden = true
            updateHUD()
        case .won, .lost:
            resetBattle()
        }
    }

    private func setupOverlay() {
        overlayNode.fontSize = 28
        overlayNode.fontColor = .white
        overlayNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlayNode.zPosition = 1000
        overlayNode.isHidden = true
        addChild(overlayNode)
    }

    private func updateOverlay(_ text: String) {
        overlayNode.text = text
        overlayNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlayNode.isHidden = false
        updateHUD()
    }

    private func render() {
        renderObstacles()
        renderFortress()
        renderTank(player, palette: .player)
        enemies.forEach { renderTank($0, palette: .enemy) }
        renderBullets()
        updateHUD()
        removeStaleNodes()
    }

    private func renderObstacles() {
        map.obstacles.forEach { obstacle in
            renderObstacle(obstacle)
        }
    }

    private func renderFortress() {
        let node = containerNode(id: "fortress", center: fortress.frame.center.cgPoint)
        node.removeAllChildren()
        node.zPosition = 20
        node.zRotation = 0

        let width = fortress.frame.size.width
        let height = fortress.frame.size.height
        let base = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 6)
        base.fillColor = .systemYellow
        base.strokeColor = .black
        base.lineWidth = 2
        node.addChild(base)

        let roofPath = CGMutablePath()
        roofPath.move(to: CGPoint(x: -width * 0.38, y: height * 0.05))
        roofPath.addLine(to: CGPoint(x: 0, y: height * 0.42))
        roofPath.addLine(to: CGPoint(x: width * 0.38, y: height * 0.05))
        roofPath.closeSubpath()

        let roof = SKShapeNode(path: roofPath)
        roof.fillColor = .systemOrange
        roof.strokeColor = .black
        roof.lineWidth = 1.5
        node.addChild(roof)

        let health = SKLabelNode(fontNamed: "AvenirNext-Bold")
        health.text = "BASE \(fortress.health)"
        health.fontSize = 10
        health.fontColor = .black
        health.verticalAlignmentMode = .center
        health.position = CGPoint(x: 0, y: -height * 0.22)
        node.addChild(health)
    }

    private func renderTank(_ tank: Tank, palette: TankPalette) {
        let node = containerNode(id: tank.id, center: tank.frame.center.cgPoint)
        node.removeAllChildren()
        node.zPosition = 30
        node.zRotation = switch tank.direction {
        case .up: 0
        case .left: .pi / 2
        case .down: .pi
        case .right: -.pi / 2
        }

        let width = tank.frame.size.width
        let height = tank.frame.size.height
        let treadSize = CGSize(width: width * 0.22, height: height * 0.88)
        let bodySize = CGSize(width: width * 0.68, height: height * 0.78)

        [-width * 0.31, width * 0.31].forEach { x in
            let tread = SKShapeNode(rectOf: treadSize, cornerRadius: 4)
            tread.fillColor = palette.tread
            tread.strokeColor = .black
            tread.lineWidth = 1
            tread.position = CGPoint(x: x, y: 0)
            node.addChild(tread)
        }

        let body = SKShapeNode(rectOf: bodySize, cornerRadius: 6)
        body.fillColor = palette.body
        body.strokeColor = .white
        body.lineWidth = tank.isPlayer ? 2.5 : 1.5
        node.addChild(body)

        let turret = SKShapeNode(circleOfRadius: width * 0.19)
        turret.fillColor = palette.turret
        turret.strokeColor = .black
        turret.lineWidth = 1.2
        node.addChild(turret)

        let barrel = SKShapeNode(rectOf: CGSize(width: width * 0.15, height: height * 0.56), cornerRadius: 3)
        barrel.fillColor = palette.barrel
        barrel.strokeColor = .black
        barrel.lineWidth = 1
        barrel.position = CGPoint(x: 0, y: height * 0.38)
        node.addChild(barrel)

        let marker = SKLabelNode(fontNamed: "AvenirNext-Bold")
        marker.text = tank.isPlayer ? "YOU" : "ENEMY"
        marker.fontSize = tank.isPlayer ? 11 : 8
        marker.fontColor = .white
        marker.verticalAlignmentMode = .center
        marker.position = CGPoint(x: 0, y: -height * 0.02)
        marker.zRotation = -node.zRotation
        node.addChild(marker)
    }

    private func renderBullets() {
        bullets.forEach { bullet in
            let node = containerNode(id: bullet.id, center: bullet.frame.center.cgPoint)
            node.removeAllChildren()
            node.zPosition = 40
            node.zRotation = 0

            let bulletShape = SKShapeNode(circleOfRadius: max(4, bullet.frame.size.width / 2))
            bulletShape.fillColor = bullet.ownerID == player.id ? .systemBlue : .systemRed
            bulletShape.strokeColor = .white
            bulletShape.lineWidth = 1
            node.addChild(bulletShape)
        }
    }

    private func renderObstacle(_ obstacle: Obstacle) {
        let node = containerNode(id: "obstacle-\(obstacle.id)", center: obstacle.frame.center.cgPoint)
        node.removeAllChildren()
        node.zPosition = 10
        node.zRotation = 0

        let width = obstacle.frame.size.width
        let height = obstacle.frame.size.height
        let bodySize = CGSize(width: max(44, width * 0.82), height: max(46, height * 0.72))
        let body = SKShapeNode(rectOf: bodySize, cornerRadius: 7)
        body.fillColor = obstacle.isDirectory
            ? NSColor.systemBrown.withAlphaComponent(0.86)
            : NSColor.windowBackgroundColor.withAlphaComponent(0.88)
        body.strokeColor = obstacle.isDirectory ? .systemYellow : .systemGray
        body.lineWidth = 2
        body.position = CGPoint(x: 0, y: -height * 0.04)
        node.addChild(body)

        if obstacle.isDirectory {
            let tab = SKShapeNode(rectOf: CGSize(width: bodySize.width * 0.42, height: 12), cornerRadius: 4)
            tab.fillColor = NSColor.systemYellow.withAlphaComponent(0.92)
            tab.strokeColor = .systemBrown
            tab.lineWidth = 1
            tab.position = CGPoint(x: -bodySize.width * 0.2, y: bodySize.height * 0.34)
            node.addChild(tab)
        } else {
            let foldPath = CGMutablePath()
            foldPath.move(to: CGPoint(x: bodySize.width * 0.18, y: bodySize.height * 0.36))
            foldPath.addLine(to: CGPoint(x: bodySize.width * 0.34, y: bodySize.height * 0.2))
            foldPath.addLine(to: CGPoint(x: bodySize.width * 0.34, y: bodySize.height * 0.36))
            foldPath.closeSubpath()

            let fold = SKShapeNode(path: foldPath)
            fold.fillColor = .systemGray
            fold.strokeColor = .systemGray
            node.addChild(fold)
        }

        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.text = obstacle.label.shortened(maxLength: 10)
        label.fontSize = 9
        label.fontColor = obstacle.isDirectory ? .white : .black
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: -bodySize.height * 0.17)
        node.addChild(label)
    }

    private func containerNode(id: String, center: CGPoint) -> SKNode {
        let node: SKNode
        if let existing = nodesByID[id] {
            node = existing
        } else {
            node = SKNode()
            node.name = id
            addChild(node)
            nodesByID[id] = node
        }

        node.position = center
        return node
    }

    private func removeStaleNodes() {
        let activeIDs = Set(
            map.obstacles.map { "obstacle-\($0.id)" } +
                ["player", "fortress"] +
                enemies.map(\.id) +
                bullets.map(\.id)
        )

        nodesByID.keys
            .filter { !activeIDs.contains($0) }
            .forEach { id in
                nodesByID[id]?.removeFromParent()
                nodesByID[id] = nil
            }
    }

    private func zPosition(for id: String) -> CGFloat {
        if id.hasPrefix("obstacle-") {
            return 10
        }
        if id == "fortress" {
            return 20
        }
        if id.hasPrefix("enemy-") || id == "player" {
            return 30
        }
        return 40
    }

    private func setupHUD() {
        hudNode.zPosition = 900
        addChild(hudNode)

        hudBackground.fillColor = NSColor.black.withAlphaComponent(0.62)
        hudBackground.strokeColor = NSColor.white.withAlphaComponent(0.28)
        hudBackground.lineWidth = 1
        hudNode.addChild(hudBackground)

        hudLines.enumerated().forEach { index, line in
            line.horizontalAlignmentMode = .left
            line.verticalAlignmentMode = .center
            line.fontSize = index == 0 ? 13 : 11
            line.fontColor = index == 0 ? .white : NSColor.white.withAlphaComponent(0.88)
            hudNode.addChild(line)
        }

        updateHUD()
    }

    private func updateHUD() {
        let panelWidth: CGFloat = 340
        let panelHeight: CGFloat = 112
        let margin: CGFloat = 18
        hudNode.position = CGPoint(x: margin, y: size.height - panelHeight - margin)
        hudBackground.path = CGPath(
            roundedRect: CGRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            cornerWidth: 8,
            cornerHeight: 8,
            transform: nil
        )

        let phaseText = switch phase {
        case .ready: "Ready"
        case .running: "Running"
        case .paused: "Paused"
        case .won: "Victory"
        case .lost: "Defeat"
        }

        let texts = [
            "DeskTank  |  \(phaseText)  |  Enemies \(enemies.count)  |  Base HP \(fortress.health)",
            "Blue tank = You     Red tanks = Enemies     Yellow = Base",
            "WASD Move     J Fire     Space Pause/Resume",
            "R Restart     Esc/Q Quit     Cmd+Opt+T Hide/Show",
            "Desktop files and folders are live walls"
        ]

        zip(hudLines, texts).enumerated().forEach { index, pair in
            let (line, text) = pair
            line.text = text
            line.position = CGPoint(x: 14, y: panelHeight - 18 - CGFloat(index) * 21)
        }
    }
}

private extension Rect {
    var toCGRect: CGRect {
        CGRect(x: origin.x, y: origin.y, width: size.width, height: size.height)
    }
}

private extension Point {
    var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }
}

private extension String {
    func shortened(maxLength: Int) -> String {
        guard count > maxLength else {
            return self
        }

        return String(prefix(maxLength - 1)) + "..."
    }
}

private struct TankPalette {
    let body: NSColor
    let turret: NSColor
    let barrel: NSColor
    let tread: NSColor

    static let player = TankPalette(
        body: .systemBlue,
        turret: .controlAccentColor,
        barrel: .systemBlue,
        tread: NSColor(calibratedWhite: 0.08, alpha: 1)
    )

    static let enemy = TankPalette(
        body: .systemRed,
        turret: .systemPink,
        barrel: .systemRed,
        tread: NSColor(calibratedWhite: 0.08, alpha: 1)
    )
}
