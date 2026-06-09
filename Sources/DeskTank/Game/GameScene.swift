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
    private let backdropNode = SKNode()
    private let statsPanel = BattleStatsPanel()
    private let statsStore = GameStatsStore()
    private var stats = GameStats()

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
        setupBackdrop()
        setupOverlay()
        stats = statsStore.load()
        addChild(statsPanel)
        updateStatsPanel()
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
        updateStatsPanel()
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
        map = MapModel(bounds: bounds)
            .replacingDesktopItems(items)
            .includingStaticObstacles([statsPanelObstacle()])
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
        stats = stats.resettingCurrentRun()
        statsStore.save(stats)
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
                recordKill()
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
        if phase == .running, nextPhase != .running {
            recordRoundOutcome(nextPhase)
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
            updateStatsPanel()
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

    private func setupBackdrop() {
        backdropNode.zPosition = -100
        addChild(backdropNode)

        let wash = SKShapeNode(rect: CGRect(origin: .zero, size: size))
        wash.fillColor = NSColor(calibratedRed: 0.04, green: 0.08, blue: 0.10, alpha: 0.22)
        wash.strokeColor = .clear
        backdropNode.addChild(wash)

        let gridPath = CGMutablePath()
        stride(from: 0.0, through: size.width, by: 48).forEach { x in
            gridPath.move(to: CGPoint(x: x, y: 0))
            gridPath.addLine(to: CGPoint(x: x, y: size.height))
        }
        stride(from: 0.0, through: size.height, by: 48).forEach { y in
            gridPath.move(to: CGPoint(x: 0, y: y))
            gridPath.addLine(to: CGPoint(x: size.width, y: y))
        }

        let grid = SKShapeNode(path: gridPath)
        grid.strokeColor = NSColor.white.withAlphaComponent(0.045)
        grid.lineWidth = 1
        backdropNode.addChild(grid)
    }

    private func updateOverlay(_ text: String) {
        overlayNode.text = text
        overlayNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlayNode.isHidden = false
        updateStatsPanel()
    }

    private func render() {
        renderObstacles()
        renderFortress()
        renderTank(player, palette: .player)
        enemies.forEach { renderTank($0, palette: .enemy) }
        renderBullets()
        updateStatsPanel()
        removeStaleNodes()
    }

    private func renderObstacles() {
        map.obstacles
            .filter { $0.id != "stats-panel" }
            .forEach { obstacle in
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
        let shadow = SKShapeNode(rectOf: CGSize(width: width * 1.08, height: height * 0.92), cornerRadius: 10)
        shadow.fillColor = NSColor.black.withAlphaComponent(0.34)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 3, y: -4)
        node.addChild(shadow)

        let outerWall = SKShapeNode(rectOf: CGSize(width: width * 1.05, height: height * 0.95), cornerRadius: 8)
        outerWall.fillColor = NSColor(calibratedRed: 0.17, green: 0.18, blue: 0.19, alpha: 0.96)
        outerWall.strokeColor = NSColor(calibratedRed: 1.0, green: 0.82, blue: 0.20, alpha: 1)
        outerWall.lineWidth = 3
        node.addChild(outerWall)

        let base = SKShapeNode(rectOf: CGSize(width: width * 0.76, height: height * 0.58), cornerRadius: 6)
        base.fillColor = NSColor(calibratedRed: 0.98, green: 0.70, blue: 0.16, alpha: 1)
        base.strokeColor = NSColor(calibratedRed: 0.15, green: 0.09, blue: 0.02, alpha: 1)
        base.lineWidth = 1.6
        base.position = CGPoint(x: 0, y: -height * 0.06)
        node.addChild(base)

        let roofPath = CGMutablePath()
        roofPath.move(to: CGPoint(x: -width * 0.42, y: height * 0.06))
        roofPath.addLine(to: CGPoint(x: 0, y: height * 0.40))
        roofPath.addLine(to: CGPoint(x: width * 0.42, y: height * 0.06))
        roofPath.closeSubpath()

        let roof = SKShapeNode(path: roofPath)
        roof.fillColor = NSColor(calibratedRed: 0.86, green: 0.16, blue: 0.10, alpha: 1)
        roof.strokeColor = NSColor(calibratedRed: 0.17, green: 0.04, blue: 0.02, alpha: 1)
        roof.lineWidth = 1.5
        node.addChild(roof)

        let core = SKShapeNode(rectOf: CGSize(width: width * 0.25, height: height * 0.28), cornerRadius: 3)
        core.fillColor = NSColor(calibratedRed: 1.0, green: 0.93, blue: 0.48, alpha: 1)
        core.strokeColor = NSColor.black.withAlphaComponent(0.65)
        core.lineWidth = 1
        core.position = CGPoint(x: 0, y: -height * 0.11)
        node.addChild(core)

        let health = SKLabelNode(fontNamed: "AvenirNext-Bold")
        health.text = "HP \(fortress.health)"
        health.fontSize = 9
        health.fontColor = .white
        health.verticalAlignmentMode = .center
        health.position = CGPoint(x: 0, y: -height * 0.41)
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
        let shadow = SKShapeNode(ellipseOf: CGSize(width: width * 1.18, height: height * 0.44))
        shadow.fillColor = NSColor.black.withAlphaComponent(0.35)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 3, y: -height * 0.38)
        node.addChild(shadow)

        let treadSize = CGSize(width: width * 0.24, height: height * 0.92)
        let bodySize = CGSize(width: width * 0.66, height: height * 0.78)

        [-width * 0.31, width * 0.31].forEach { x in
            let tread = SKShapeNode(rectOf: treadSize, cornerRadius: 4)
            tread.fillColor = palette.tread
            tread.strokeColor = palette.darkStroke
            tread.lineWidth = 1
            tread.position = CGPoint(x: x, y: 0)
            node.addChild(tread)

            stride(from: -height * 0.31, through: height * 0.31, by: height * 0.19).forEach { y in
                let plate = SKShapeNode(rectOf: CGSize(width: treadSize.width * 0.72, height: 2), cornerRadius: 1)
                plate.fillColor = NSColor.white.withAlphaComponent(0.18)
                plate.strokeColor = .clear
                plate.position = CGPoint(x: x, y: y)
                node.addChild(plate)
            }
        }

        let hullBack = SKShapeNode(rectOf: CGSize(width: width * 0.78, height: height * 0.72), cornerRadius: 7)
        hullBack.fillColor = palette.darkStroke
        hullBack.strokeColor = .clear
        hullBack.position = CGPoint(x: 0, y: -height * 0.02)
        node.addChild(hullBack)

        let hullPath = CGMutablePath()
        hullPath.move(to: CGPoint(x: -bodySize.width * 0.42, y: -bodySize.height * 0.44))
        hullPath.addLine(to: CGPoint(x: bodySize.width * 0.42, y: -bodySize.height * 0.44))
        hullPath.addLine(to: CGPoint(x: bodySize.width * 0.50, y: bodySize.height * 0.18))
        hullPath.addLine(to: CGPoint(x: bodySize.width * 0.28, y: bodySize.height * 0.48))
        hullPath.addLine(to: CGPoint(x: -bodySize.width * 0.28, y: bodySize.height * 0.48))
        hullPath.addLine(to: CGPoint(x: -bodySize.width * 0.50, y: bodySize.height * 0.18))
        hullPath.closeSubpath()

        let body = SKShapeNode(path: hullPath)
        body.fillColor = palette.body
        body.strokeColor = palette.trim
        body.lineWidth = tank.isPlayer ? 2.6 : 1.8
        node.addChild(body)

        [-width * 0.30, width * 0.30].forEach { x in
            stride(from: -height * 0.26, through: height * 0.22, by: height * 0.16).forEach { y in
                let wheel = SKShapeNode(circleOfRadius: width * 0.045)
                wheel.fillColor = NSColor.black.withAlphaComponent(0.72)
                wheel.strokeColor = NSColor.white.withAlphaComponent(0.22)
                wheel.lineWidth = 0.7
                wheel.position = CGPoint(x: x, y: y)
                node.addChild(wheel)
            }
        }

        let highlight = SKShapeNode(rectOf: CGSize(width: width * 0.44, height: height * 0.10), cornerRadius: 3)
        highlight.fillColor = NSColor.white.withAlphaComponent(0.24)
        highlight.strokeColor = .clear
        highlight.position = CGPoint(x: -width * 0.03, y: height * 0.18)
        node.addChild(highlight)

        let armorStripe = SKShapeNode(rectOf: CGSize(width: width * 0.12, height: height * 0.62), cornerRadius: 2)
        armorStripe.fillColor = NSColor.black.withAlphaComponent(0.18)
        armorStripe.strokeColor = .clear
        armorStripe.position = CGPoint(x: width * 0.17, y: 0)
        node.addChild(armorStripe)

        let turretBase = SKShapeNode(circleOfRadius: width * 0.23)
        turretBase.fillColor = palette.darkStroke
        turretBase.strokeColor = .clear
        node.addChild(turretBase)

        let turret = SKShapeNode(circleOfRadius: width * 0.18)
        turret.fillColor = palette.turret
        turret.strokeColor = palette.trim
        turret.lineWidth = 1.2
        node.addChild(turret)

        let hatch = SKShapeNode(circleOfRadius: width * 0.075)
        hatch.fillColor = palette.darkStroke.withAlphaComponent(0.92)
        hatch.strokeColor = NSColor.white.withAlphaComponent(0.28)
        hatch.lineWidth = 0.8
        hatch.position = CGPoint(x: -width * 0.05, y: width * 0.04)
        node.addChild(hatch)

        let barrel = SKShapeNode(rectOf: CGSize(width: width * 0.14, height: height * 0.62), cornerRadius: 3)
        barrel.fillColor = palette.barrel
        barrel.strokeColor = palette.darkStroke
        barrel.lineWidth = 1
        barrel.position = CGPoint(x: 0, y: height * 0.42)
        node.addChild(barrel)

        let muzzle = SKShapeNode(rectOf: CGSize(width: width * 0.22, height: height * 0.10), cornerRadius: 3)
        muzzle.fillColor = palette.darkStroke
        muzzle.strokeColor = .clear
        muzzle.position = CGPoint(x: 0, y: height * 0.75)
        node.addChild(muzzle)

        let antenna = SKShapeNode()
        let antennaPath = CGMutablePath()
        antennaPath.move(to: CGPoint(x: width * 0.16, y: height * 0.14))
        antennaPath.addLine(to: CGPoint(x: width * 0.31, y: height * 0.43))
        antenna.path = antennaPath
        antenna.strokeColor = NSColor.white.withAlphaComponent(0.45)
        antenna.lineWidth = 1
        node.addChild(antenna)

        let marker = SKLabelNode(fontNamed: "AvenirNext-Bold")
        marker.text = tank.isPlayer ? "P1" : "CPU"
        marker.fontSize = tank.isPlayer ? 10 : 8
        marker.fontColor = .white
        marker.verticalAlignmentMode = .center
        marker.position = CGPoint(x: 0, y: -height * 0.08)
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
        let shadow = SKShapeNode(ellipseOf: CGSize(width: max(50, width * 0.86), height: 14))
        shadow.fillColor = NSColor.black.withAlphaComponent(0.26)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 3, y: -height * 0.43)
        node.addChild(shadow)

        let bodySize = CGSize(width: max(52, width * 0.86), height: max(50, height * 0.78))

        if obstacle.isDirectory {
            ObstacleArt.renderCastle(node: node, size: bodySize, height: height)
        } else {
            ObstacleArt.renderWall(node: node, size: bodySize, height: height)
        }

        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.text = obstacle.label.shortened(maxLength: 10)
        label.fontSize = 9
        label.fontColor = obstacle.isDirectory
            ? NSColor(calibratedRed: 0.16, green: 0.09, blue: 0.02, alpha: 1)
            : NSColor(calibratedRed: 0.15, green: 0.20, blue: 0.28, alpha: 1)
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: -bodySize.height * 0.24)
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

    private func updateStatsPanel() {
        statsPanel.update(
            phase: phase,
            enemiesRemaining: enemies.count,
            fortressHealth: fortress.health,
            stats: stats,
            sceneSize: size
        )
    }

    private func statsPanelObstacle() -> Obstacle {
        Obstacle(
            id: "stats-panel",
            frame: BattleStatsPanel.obstacleFrame(sceneSize: size),
            label: "Stats Panel",
            isDirectory: true
        )
    }

    private func recordKill() {
        stats = stats.recordingKill()
        statsStore.save(stats)
    }

    private func recordRoundOutcome(_ nextPhase: GamePhase) {
        switch nextPhase {
        case .won:
            stats = stats.recordingWin()
        case .lost:
            stats = stats.recordingFailure()
        case .ready, .running, .paused:
            return
        }

        statsStore.save(stats)
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
