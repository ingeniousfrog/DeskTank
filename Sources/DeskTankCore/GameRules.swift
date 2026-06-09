import Foundation

public struct GameRules: Sendable {
    public let tankSpeed: Double
    public let bulletSpeed: Double
    public let enemyFireInterval: Double
    public let reloadDuration: Double

    public init(
        tankSpeed: Double = 180,
        bulletSpeed: Double = 420,
        enemyFireInterval: Double = 1.35,
        reloadDuration: Double = 0.35
    ) {
        self.tankSpeed = tankSpeed
        self.bulletSpeed = bulletSpeed
        self.enemyFireInterval = enemyFireInterval
        self.reloadDuration = reloadDuration
    }

    public func movedTank(_ tank: Tank, direction: Direction, deltaTime: Double, map: MapModel) -> Tank {
        let vector = direction.vector
        let candidate = Rect(
            origin: tank.frame.origin.offset(
                dx: vector.x * tankSpeed * deltaTime,
                dy: vector.y * tankSpeed * deltaTime
            ),
            size: tank.frame.size
        )

        let nextFrame = map.isBlocked(candidate) ? tank.frame : candidate
        return Tank(
            id: tank.id,
            frame: nextFrame,
            direction: direction,
            isPlayer: tank.isPlayer,
            reloadRemaining: max(0, tank.reloadRemaining - deltaTime)
        )
    }

    public func firedBullet(from tank: Tank, bulletID: String) -> Bullet? {
        guard tank.reloadRemaining <= 0 else {
            return nil
        }

        let bulletSize = Size(width: 8, height: 8)
        let center = tank.frame.center
        let vector = tank.direction.vector
        let origin = Point(
            x: center.x - bulletSize.width / 2 + vector.x * tank.frame.size.width / 2,
            y: center.y - bulletSize.height / 2 + vector.y * tank.frame.size.height / 2
        )

        return Bullet(
            id: bulletID,
            frame: Rect(origin: origin, size: bulletSize),
            direction: tank.direction,
            ownerID: tank.id
        )
    }

    public func movedBullet(_ bullet: Bullet, deltaTime: Double) -> Bullet {
        let vector = bullet.direction.vector
        return Bullet(
            id: bullet.id,
            frame: Rect(
                origin: bullet.frame.origin.offset(
                    dx: vector.x * bulletSpeed * deltaTime,
                    dy: vector.y * bulletSpeed * deltaTime
                ),
                size: bullet.frame.size
            ),
            direction: bullet.direction,
            ownerID: bullet.ownerID
        )
    }
}
