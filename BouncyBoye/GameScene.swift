//
//  GameScene.swift
//  BouncyBoye
//
//  Created by Cole Hassett on 5/4/18.
//  Copyright © 2018 Cole Hassett. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var backgroundNode: SKNode!
    var midgroundNode: SKNode!
    var foregroundNode: SKNode!
    var hudNode: SKNode!
    var player: SKNode!
    
    let tapToStartNode = SKSpriteNode(imageNamed: "TapToStart")
    
    var scaleFactor: CGFloat!
    
    var endLevelY = 0
    var maxPlayerY: Int!
    
    var labelScore: SKLabelNode!
    var labelPointItems: SKLabelNode!
    
    var gameOver = false
    
    let motionManager = CMMotionManager()
    var xAcceleration: CGFloat = 0.0
    
    let PLAYER_IMAGE = "dog"
    let POINT_ITEM_IMAGE = "Star"
    let POINT_ITEM_SPECIAL_IMAGE = "StarSpecial"
    let PLATFORM_IMAGE = "Platform"
    let PLATFORM_SPECIAL_IMAGE = "PlatformBreak"
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        
        maxPlayerY = 80
        GameState.sharedInstance.score = 0
        gameOver = false
        
        backgroundColor = SKColor.white
        scaleFactor = self.size.width / 320
        backgroundNode = createBackgroundNode()
        addChild(backgroundNode)
        
        let levelPlist = Bundle.main.path(forResource: "Level01", ofType: "plist")
        let levelData = NSDictionary(contentsOfFile: levelPlist!)!
        endLevelY = levelData["EndY"]! as! Int
        
        foregroundNode = SKNode()
        addChild(foregroundNode)
        
        let pointItems = levelData["PointItems"] as! NSDictionary
        let itemPatterns = pointItems["Patterns"] as! NSDictionary
        let itemPositions = pointItems["Positions"] as! [NSDictionary]
        
        for itemPosition in itemPositions {
            
            let patternX = itemPosition["x"] as! Float
            let patternY = itemPosition["y"] as! Float
            let pattern = itemPosition["pattern"] as! String
            let itemPattern = itemPatterns[pattern] as! [NSDictionary]
            
            for itemPoint in itemPattern {
                
                let x = itemPoint["x"] as! Float
                let y = itemPoint["y"] as! Float
                let type = PointItemType(rawValue: itemPoint["type"] as! Int)
                let positionX = CGFloat(x + patternX)
                let positionY = CGFloat(y + patternY)
                let pointItemNode = createPointAtPosition(position: CGPoint(x: positionX, y: positionY), type: type!)
                foregroundNode.addChild(pointItemNode)
            }
        }
        
        let platforms = levelData["Platforms"] as! NSDictionary
        let platformPatterns = platforms["Patterns"] as! NSDictionary
        let platformPositions = platforms["Positions"] as! [NSDictionary]
        
        for position in platformPositions {
            
            let patternX = position["x"] as! Float
            let patternY = position["y"] as! Float
            let pattern = position["pattern"] as! String
            let platformPattern = platformPatterns[pattern] as! [NSDictionary]
            
            for point in platformPattern {
                
                let x = point["x"] as! Float
                let y = point["y"] as! Float
                let type = PlatformType(rawValue: point["type"] as! Int)
                let positionX = CGFloat(x + patternX)
                let positionY = CGFloat(y + patternY)
                let platformNode = createPlatformAtPosition(position: CGPoint(x: positionX, y: positionY), type: type!)
                foregroundNode.addChild(platformNode)
            }
        }
        
        player = createPlayer()
        foregroundNode.addChild(player)
        
        hudNode = SKNode()
        tapToStartNode.position = CGPoint(x: self.size.width / 2, y: 180.0)
        
        let pointCounterImage = SKSpriteNode(imageNamed: POINT_ITEM_IMAGE)
        pointCounterImage.position = CGPoint(x: 25, y: self.size.height-30)
        hudNode.addChild(pointCounterImage)
        
        labelPointItems = SKLabelNode(fontNamed: "ChalkboardSE-Bold")
        labelPointItems.fontSize = 30
        labelPointItems.fontColor = SKColor.blue
        labelPointItems.position = CGPoint(x: 50, y: self.size.height-40)
        labelPointItems.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        labelPointItems.text = "X \(GameState.sharedInstance.pointItems)"
        hudNode.addChild(labelPointItems)
        
        labelScore = SKLabelNode(fontNamed: "ChalkboardSE-Bold")
        labelScore.fontSize = 30
        labelScore.fontColor = SKColor.magenta
        labelScore.position = CGPoint(x: self.size.width-20, y: self.size.height-40)
        labelScore.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.right
        labelScore.text = "0"
        hudNode.addChild(labelScore)
        
        motionManager.accelerometerUpdateInterval = 0.2
        
        motionManager.startAccelerometerUpdates()
        
//        motionManager.startAccelerometerUpdates(to: OperationQueue.current!, withHandler: {
//            (accelerometerData: CMAccelerometerData!, error: NSError!) in
//            let acceleration = accelerometerData.acceleration
//            self.xAcceleration = (CGFloat(acceleration.x)*0.75) + (self.xAcceleration * 0.25)
//        })
        
        hudNode.addChild(tapToStartNode)
        addChild(hudNode)
        
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -2.0)
        physicsWorld.contactDelegate = self
        
    }
    
    func createBackgroundNode() -> SKNode {
        
        let backgroundNode = SKNode()
        let ySpacing = 64.0 * scaleFactor
        
        for index in 0...19 {
            let node = SKSpriteNode(imageNamed:String(format: "Background%02d", index+1))
            node.setScale(scaleFactor)
            node.anchorPoint = CGPoint(x: 0.5, y: 0.0)
            node.position = CGPoint(x: self.size.width / 2, y: ySpacing * CGFloat(index))
            backgroundNode.addChild(node)
        }
        
        return backgroundNode
        
    }
    
    func createPlayer() -> SKNode {
        let playerNode = SKNode()
        playerNode.position = CGPoint(x: self.size.width / 2, y: 80.0)
        
        let sprite = SKSpriteNode(imageNamed: "Player")
        playerNode.addChild(sprite)
        
        playerNode.physicsBody = SKPhysicsBody(circleOfRadius: sprite.size.width / 2)
        playerNode.physicsBody?.isDynamic = false
        playerNode.physicsBody?.allowsRotation = false
        playerNode.physicsBody?.restitution = 1.0
        playerNode.physicsBody?.friction = 0.0
        playerNode.physicsBody?.angularDamping = 0.0
        playerNode.physicsBody?.linearDamping = 0.0
        playerNode.physicsBody?.usesPreciseCollisionDetection = true
        playerNode.physicsBody?.categoryBitMask = CollisionCategoryBitmask.Player
        playerNode.physicsBody?.collisionBitMask = 0
        playerNode.physicsBody?.contactTestBitMask = CollisionCategoryBitmask.PointItem | CollisionCategoryBitmask.Platform
        
        return playerNode
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if player.physicsBody!.isDynamic {
            for touch in touches {
                let location = touch.location(in: self)
                if (location.x < self.frame.size.width/2) {
                    player.position = CGPoint(x: player.position.x - 30.0, y: player.position.y)
                }
                else {
                    player.position = CGPoint(x: player.position.x + 30.0, y: player.position.y)
                }
            }
            return
        }
        
        tapToStartNode.removeFromParent()
        player.physicsBody?.isDynamic = true
        player.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: 20.0))
        
    }
    
    func createPointAtPosition(position: CGPoint, type: PointItemType) -> PointNode {
        
        let node = PointNode()
        let thePosition = CGPoint(x: position.x * scaleFactor, y: position.y)
        node.position = thePosition
        node.name = "NODE_POINT"
        
        node.pointItemType = type
        var sprite: SKSpriteNode
        if type == .Special {
            sprite = SKSpriteNode(imageNamed: POINT_ITEM_SPECIAL_IMAGE)
        }
        else {
            sprite = SKSpriteNode(imageNamed: POINT_ITEM_IMAGE)
        }
        node.addChild(sprite)
        node.physicsBody = SKPhysicsBody(circleOfRadius: sprite.size.width / 2)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = CollisionCategoryBitmask.PointItem
        node.physicsBody?.collisionBitMask = 0
        
        return node
        
    }
    
    func createPlatformAtPosition(position: CGPoint, type: PlatformType) -> PlatformNode {
        
        let node = PlatformNode()
        let thePosition = CGPoint(x: position.x * scaleFactor, y: position.y)
        node.position = thePosition
        node.name = "NODE_PLATFORM"
        
        node.platformType = type
        var sprite: SKSpriteNode
        if type == .Break {
            sprite = SKSpriteNode(imageNamed: PLATFORM_SPECIAL_IMAGE)
        }
        else {
            sprite = SKSpriteNode(imageNamed: PLATFORM_IMAGE)
        }
        node.addChild(sprite)
        
        node.physicsBody = SKPhysicsBody(rectangleOf: sprite.size)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = CollisionCategoryBitmask.Platform
        node.physicsBody?.collisionBitMask = 0
        
        return node
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        var updateHUD = false
        let whichNode = (contact.bodyA.node != player) ? contact.bodyA.node : contact.bodyB.node
        let pointItemNode = whichNode as! GameObjectNode
        
        updateHUD = pointItemNode.collisionWithPlayer(player: player)
        
        if updateHUD {
            labelScore.text = "\(GameState.sharedInstance.score)"
            labelPointItems.text = "X \(GameState.sharedInstance.pointItems)"
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        if gameOver {
            return
        }
        
        if Int(player.position.y) > maxPlayerY! {
            
            GameState.sharedInstance.score += Int(player.position.y) - maxPlayerY!
            maxPlayerY = Int(player.position.y)
            labelScore.text = "\(GameState.sharedInstance.score)"
        }
        
        foregroundNode.enumerateChildNodes(withName: "NODE_PLATFORM", using: {
            (node, stop) in
            let platform = node as! PlatformNode
            platform.checkNodeRemoval(playerY: self.player.position.y)
        })
        
        foregroundNode.enumerateChildNodes(withName: "NODE_POINT", using: {
            (node, stop) in
            let pointItem = node as! PointNode
            pointItem.checkNodeRemoval(playerY: self.player.position.y)
        })
        
        if player.position.y > 200.0 {
            
            backgroundNode.position = CGPoint(x: 0.0, y: -((player.position.y - 200.0) / 10))
            foregroundNode.position = CGPoint(x: 0.0, y: -(player.position.y - 200.0))
        }
        
        if Int(player.position.y) < maxPlayerY - 800 {
            endGame()
        }
    }
    
    func endGame() {
        
        gameOver = true
        
        GameState.sharedInstance.saveState()
        
        let reveal = SKTransition.fade(withDuration: 0.5)
        let endGameScene = EndGameScene(size: self.size)
        self.view!.presentScene(endGameScene, transition: reveal)
        
    }
    
    override func didSimulatePhysics() {
        
        player.physicsBody?.velocity = CGVector(dx: xAcceleration * 400.0, dy: player.physicsBody!.velocity.dy)
        
        if player.position.x < -20.0 {
            player.position = CGPoint(x: self.size.width + 20.0, y: player.position.y)
        }
        else if (player.position.x > self.size.width + 20.0) {
            player.position = CGPoint(x: -20.0, y: player.position.y)
        }
    }
}









