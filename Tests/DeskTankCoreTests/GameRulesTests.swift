import Testing
@testable import DeskTankCore

@Test func tankMovesInRequestedDirectionWhenPathIsOpen() {
    let map = MapModel(bounds: Rect(origin: Point(x: 0, y: 0), size: Size(width: 400, height: 400)))
    let rules = GameRules(tankSpeed: 100)
    let tank = Tank(
        id: "player",
        frame: Rect(origin: Point(x: 50, y: 50), size: Size(width: 40, height: 40)),
        direction: .up,
        isPlayer: true
    )

    let moved = rules.movedTank(tank, direction: .right, deltaTime: 0.5, map: map)

    #expect(moved.frame.origin == Point(x: 100, y: 50))
    #expect(moved.direction == .right)
}

@Test func tankDoesNotMoveThroughObstacle() {
    let map = MapModel(
        bounds: Rect(origin: Point(x: 0, y: 0), size: Size(width: 400, height: 400)),
        obstacles: [
            Obstacle(
                id: "file",
                frame: Rect(origin: Point(x: 100, y: 40), size: Size(width: 80, height: 80)),
                label: "File"
            )
        ]
    )
    let rules = GameRules(tankSpeed: 100)
    let tank = Tank(
        id: "player",
        frame: Rect(origin: Point(x: 50, y: 50), size: Size(width: 40, height: 40)),
        direction: .right,
        isPlayer: true
    )

    let moved = rules.movedTank(tank, direction: .right, deltaTime: 0.5, map: map)

    #expect(moved.frame == tank.frame)
}

@Test func bulletSpawnsAtTankMuzzleAndMovesForward() throws {
    let rules = GameRules(bulletSpeed: 200)
    let tank = Tank(
        id: "player",
        frame: Rect(origin: Point(x: 80, y: 80), size: Size(width: 40, height: 40)),
        direction: .up,
        isPlayer: true
    )

    let bullet = try #require(rules.firedBullet(from: tank, bulletID: "b1"))
    let moved = rules.movedBullet(bullet, deltaTime: 0.25)

    #expect(bullet.frame.origin == Point(x: 96, y: 116))
    #expect(moved.frame.origin == Point(x: 96, y: 166))
}
