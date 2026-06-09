import AppKit
import SpriteKit

@MainActor
enum ObstacleArt {
    static func renderCastle(node: SKNode, size: CGSize, height: Double) {
        let stone = NSColor(calibratedRed: 0.52, green: 0.48, blue: 0.42, alpha: 0.98)
        let dark = NSColor(calibratedRed: 0.22, green: 0.20, blue: 0.18, alpha: 1)
        let roof = NSColor(calibratedRed: 0.58, green: 0.12, blue: 0.10, alpha: 1)

        [-size.width * 0.34, size.width * 0.34].forEach { x in
            let tower = SKShapeNode(rectOf: CGSize(width: size.width * 0.28, height: size.height * 0.76), cornerRadius: 5)
            tower.fillColor = stone
            tower.strokeColor = dark
            tower.lineWidth = 1.8
            tower.position = CGPoint(x: x, y: -height * 0.04)
            node.addChild(tower)

            let cap = SKShapeNode(rectOf: CGSize(width: size.width * 0.34, height: 10), cornerRadius: 2)
            cap.fillColor = roof
            cap.strokeColor = dark
            cap.lineWidth = 1
            cap.position = CGPoint(x: x, y: size.height * 0.34)
            node.addChild(cap)
        }

        let keep = SKShapeNode(rectOf: CGSize(width: size.width * 0.54, height: size.height * 0.62), cornerRadius: 5)
        keep.fillColor = NSColor(calibratedRed: 0.62, green: 0.57, blue: 0.50, alpha: 0.98)
        keep.strokeColor = dark
        keep.lineWidth = 2
        keep.position = CGPoint(x: 0, y: -height * 0.10)
        node.addChild(keep)

        [-0.18, 0, 0.18].forEach { offset in
            let merlon = SKShapeNode(rectOf: CGSize(width: size.width * 0.12, height: size.height * 0.16), cornerRadius: 2)
            merlon.fillColor = stone
            merlon.strokeColor = dark
            merlon.lineWidth = 0.8
            merlon.position = CGPoint(x: size.width * offset, y: size.height * 0.27)
            node.addChild(merlon)
        }

        let gate = SKShapeNode(rectOf: CGSize(width: size.width * 0.19, height: size.height * 0.25), cornerRadius: 3)
        gate.fillColor = NSColor(calibratedRed: 0.18, green: 0.12, blue: 0.08, alpha: 1)
        gate.strokeColor = NSColor.black.withAlphaComponent(0.7)
        gate.lineWidth = 1
        gate.position = CGPoint(x: 0, y: -size.height * 0.22)
        node.addChild(gate)
    }

    static func renderWall(node: SKNode, size: CGSize, height: Double) {
        let mortar = NSColor(calibratedRed: 0.26, green: 0.24, blue: 0.22, alpha: 1)
        let body = SKShapeNode(rectOf: size, cornerRadius: 5)
        body.fillColor = NSColor(calibratedRed: 0.55, green: 0.45, blue: 0.35, alpha: 0.98)
        body.strokeColor = mortar
        body.lineWidth = 2
        body.position = CGPoint(x: 0, y: -height * 0.04)
        node.addChild(body)

        stride(from: -size.height * 0.24, through: size.height * 0.24, by: size.height * 0.18).enumerated().forEach { row, y in
            let offset = row.isMultiple(of: 2) ? 0 : size.width * 0.13
            stride(from: -size.width * 0.32, through: size.width * 0.32, by: size.width * 0.24).forEach { x in
                let brick = SKShapeNode(rectOf: CGSize(width: size.width * 0.18, height: size.height * 0.11), cornerRadius: 2)
                brick.fillColor = NSColor(calibratedRed: 0.68, green: 0.54, blue: 0.40, alpha: 1)
                brick.strokeColor = mortar.withAlphaComponent(0.7)
                brick.lineWidth = 0.7
                brick.position = CGPoint(x: x + offset, y: y - height * 0.04)
                node.addChild(brick)
            }
        }

        [-0.30, -0.10, 0.10, 0.30].forEach { offset in
            let crenel = SKShapeNode(rectOf: CGSize(width: size.width * 0.13, height: size.height * 0.16), cornerRadius: 2)
            crenel.fillColor = NSColor(calibratedRed: 0.62, green: 0.50, blue: 0.38, alpha: 1)
            crenel.strokeColor = mortar
            crenel.lineWidth = 0.8
            crenel.position = CGPoint(x: size.width * offset, y: size.height * 0.42)
            node.addChild(crenel)
        }
    }
}
