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
        default:
            break
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
    }

    private func render() {
        renderObstacles()
        renderFortress()
        renderTank(player, color: .systemTeal)
        enemies.forEach { renderTank($0, color: .systemRed) }
        renderBullets()
        removeStaleNodes()
    }

    private func renderObstacles() {
        map.obstacles.forEach { obstacle in
            let node = shapeNode(id: "obstacle-\(obstacle.id)", frame: obstacle.frame, color: .systemGray.withAlphaComponent(0.72))
            node.strokeColor = .white.withAlphaComponent(0.35)
            node.lineWidth = 1
        }
    }

    private func renderFortress() {
        let node = shapeNode(id: "fortress", frame: fortress.frame, color: .systemYellow.withAlphaComponent(0.9))
        node.strokeColor = .black
        node.lineWidth = 2
    }

    private func renderTank(_ tank: Tank, color: NSColor) {
        let node = shapeNode(id: tank.id, frame: tank.frame, color: color)
        node.zRotation = switch tank.direction {
        case .up: 0
        case .left: .pi / 2
        case .down: .pi
        case .right: -.pi / 2
        }
    }

    private func renderBullets() {
        bullets.forEach { bullet in
            _ = shapeNode(id: bullet.id, frame: bullet.frame, color: .white)
        }
    }

    private func shapeNode(id: String, frame: Rect, color: NSColor) -> SKShapeNode {
        let node: SKShapeNode
        if let existing = nodesByID[id] as? SKShapeNode {
            node = existing
            node.path = CGPath(rect: frame.toCGRect, transform: nil)
        } else {
            node = SKShapeNode(rect: frame.toCGRect)
            node.name = id
            addChild(node)
            nodesByID[id] = node
        }

        node.fillColor = color
        node.zPosition = zPosition(for: id)
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
}

private extension Rect {
    var toCGRect: CGRect {
        CGRect(x: origin.x, y: origin.y, width: size.width, height: size.height)
    }
}
