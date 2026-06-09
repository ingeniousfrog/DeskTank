import Testing
@testable import DeskTankCore

@Test func desktopItemsBecomeObstaclesInsideMapBounds() {
    let map = MapModel(bounds: Rect(origin: Point(x: 0, y: 0), size: Size(width: 500, height: 500)))
    let items = [
        DesktopItem(
            id: "a",
            name: "Notes",
            frame: Rect(origin: Point(x: 20, y: 30), size: Size(width: 70, height: 80)),
            isDirectory: false
        ),
        DesktopItem(
            id: "b",
            name: "Offscreen",
            frame: Rect(origin: Point(x: 900, y: 900), size: Size(width: 70, height: 80)),
            isDirectory: true
        )
    ]

    let updated = map.replacingDesktopItems(items)

    #expect(updated.obstacles == [
        Obstacle(
            id: "a",
            frame: Rect(origin: Point(x: 20, y: 30), size: Size(width: 70, height: 80)),
            label: "Notes",
            isDirectory: false
        )
    ])
}

@Test func blockedFramesCannotLeaveBoundsOrCrossObstacles() {
    let obstacle = Obstacle(
        id: "folder",
        frame: Rect(origin: Point(x: 100, y: 100), size: Size(width: 80, height: 80)),
        label: "Folder"
    )
    let map = MapModel(
        bounds: Rect(origin: Point(x: 0, y: 0), size: Size(width: 300, height: 300)),
        obstacles: [obstacle]
    )

    #expect(map.isBlocked(Rect(origin: Point(x: 120, y: 120), size: Size(width: 30, height: 30))))
    #expect(map.isBlocked(Rect(origin: Point(x: -1, y: 10), size: Size(width: 30, height: 30))))
    #expect(!map.isBlocked(Rect(origin: Point(x: 10, y: 10), size: Size(width: 30, height: 30))))
}

@Test func nearestOpenFramePushesEntityOutOfNewObstacle() {
    let map = MapModel(
        bounds: Rect(origin: Point(x: 0, y: 0), size: Size(width: 400, height: 400)),
        obstacles: [
            Obstacle(
                id: "file",
                frame: Rect(origin: Point(x: 90, y: 90), size: Size(width: 90, height: 90)),
                label: "File"
            )
        ]
    )
    let tankFrame = Rect(origin: Point(x: 100, y: 100), size: Size(width: 40, height: 40))

    let resolved = map.nearestOpenFrame(to: tankFrame, step: 20)

    #expect(!map.isBlocked(resolved))
}

@Test func staticObstaclesAreIncludedInCollisionChecks() {
    let map = MapModel(
        bounds: Rect(origin: Point(x: 0, y: 0), size: Size(width: 600, height: 400))
    )
    let statsPanel = Obstacle(
        id: "stats-panel",
        frame: Rect(origin: Point(x: 18, y: 194), size: Size(width: 430, height: 188)),
        label: "Stats Panel"
    )

    let updated = map.includingStaticObstacles([statsPanel])

    #expect(updated.isBlocked(Rect(origin: Point(x: 40, y: 220), size: Size(width: 42, height: 42))))
}
