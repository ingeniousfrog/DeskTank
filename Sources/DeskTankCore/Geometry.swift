import Foundation

public struct Point: Equatable, Sendable {
    public let x: Double
    public let y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public func offset(dx: Double, dy: Double) -> Point {
        Point(x: x + dx, y: y + dy)
    }
}

public struct Size: Equatable, Sendable {
    public let width: Double
    public let height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
}

public struct Rect: Equatable, Sendable {
    public let origin: Point
    public let size: Size

    public init(origin: Point, size: Size) {
        self.origin = origin
        self.size = size
    }

    public var minX: Double { origin.x }
    public var minY: Double { origin.y }
    public var maxX: Double { origin.x + size.width }
    public var maxY: Double { origin.y + size.height }
    public var center: Point {
        Point(x: origin.x + size.width / 2, y: origin.y + size.height / 2)
    }

    public func intersects(_ other: Rect) -> Bool {
        minX < other.maxX &&
            maxX > other.minX &&
            minY < other.maxY &&
            maxY > other.minY
    }

    public func contains(_ other: Rect) -> Bool {
        other.minX >= minX &&
            other.maxX <= maxX &&
            other.minY >= minY &&
            other.maxY <= maxY
    }

    public func insetBy(dx: Double, dy: Double) -> Rect {
        Rect(
            origin: Point(x: origin.x + dx, y: origin.y + dy),
            size: Size(width: max(0, size.width - dx * 2), height: max(0, size.height - dy * 2))
        )
    }
}
