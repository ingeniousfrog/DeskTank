import Foundation

public enum Direction: CaseIterable, Equatable, Sendable {
    case up
    case left
    case down
    case right

    public var vector: Point {
        switch self {
        case .up: Point(x: 0, y: 1)
        case .left: Point(x: -1, y: 0)
        case .down: Point(x: 0, y: -1)
        case .right: Point(x: 1, y: 0)
        }
    }
}

public enum GamePhase: Equatable, Sendable {
    case ready
    case running
    case paused
    case won
    case lost
}

public struct DesktopItem: Equatable, Sendable {
    public let id: String
    public let name: String
    public let frame: Rect
    public let isDirectory: Bool

    public init(id: String, name: String, frame: Rect, isDirectory: Bool) {
        self.id = id
        self.name = name
        self.frame = frame
        self.isDirectory = isDirectory
    }
}

public struct Obstacle: Equatable, Sendable {
    public let id: String
    public let frame: Rect
    public let label: String

    public init(id: String, frame: Rect, label: String) {
        self.id = id
        self.frame = frame
        self.label = label
    }
}

public struct Tank: Equatable, Sendable {
    public let id: String
    public let frame: Rect
    public let direction: Direction
    public let isPlayer: Bool
    public let reloadRemaining: Double

    public init(
        id: String,
        frame: Rect,
        direction: Direction,
        isPlayer: Bool,
        reloadRemaining: Double = 0
    ) {
        self.id = id
        self.frame = frame
        self.direction = direction
        self.isPlayer = isPlayer
        self.reloadRemaining = reloadRemaining
    }
}

public struct Bullet: Equatable, Sendable {
    public let id: String
    public let frame: Rect
    public let direction: Direction
    public let ownerID: String

    public init(id: String, frame: Rect, direction: Direction, ownerID: String) {
        self.id = id
        self.frame = frame
        self.direction = direction
        self.ownerID = ownerID
    }
}

public struct Fortress: Equatable, Sendable {
    public let frame: Rect
    public let health: Int

    public init(frame: Rect, health: Int) {
        self.frame = frame
        self.health = health
    }
}
