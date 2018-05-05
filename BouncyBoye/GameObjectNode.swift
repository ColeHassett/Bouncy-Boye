//
//  GameObjectNode.swift
//  BouncyBoye
//
//  Created by Cole Hassett on 5/4/18.
//  Copyright © 2018 Cole Hassett. All rights reserved.
//

import SpriteKit

var jumpVelocity:CGFloat = 250.0

struct CollisionCategoryBitmask {
    static let Player: UInt32 = 0x00
    static let PointItem: UInt32 = 0x01
    static let Platform: UInt32 = 0x02
}

enum PointItemType: Int {
    case Normal = 0
    case Special
}

enum PlatformType: Int {
    case Normal = 0
    case Break
}

class GameObjectNode: SKNode {
    
    func collisionWithPlayer(player: SKNode) -> Bool {
        
        return false
        
    }
    
    func checkNodeRemoval(playerY: CGFloat) {
        
        if playerY > self.position.y + 300.0 {
            self.removeFromParent()
        }
    }
    
}

class PointNode: GameObjectNode {
    
    var pointItemType: PointItemType!
    
    override func collisionWithPlayer(player: SKNode) -> Bool {
        
//        player.physicsBody?.velocity = CGVector(dx: player.physicsBody!.velocity.dx, dy: 400.0)
        self.removeFromParent()
        GameState.sharedInstance.score += (pointItemType == .Normal ? 20 : 100)
        GameState.sharedInstance.pointItems += (pointItemType == .Normal ? 1 : 5)
        return true
        
    }
    
}

class PlatformNode: GameObjectNode {
    
    var platformType: PlatformType!
    
    override func collisionWithPlayer(player: SKNode) -> Bool {
        
        if (player.physicsBody?.velocity.dy)! < 0 {
            
            player.physicsBody?.velocity = CGVector(dx: player.physicsBody!.velocity.dx, dy: jumpVelocity)
            
            if platformType == .Break {
                self.removeFromParent()
            }
        }
        
        return false
    }
}

