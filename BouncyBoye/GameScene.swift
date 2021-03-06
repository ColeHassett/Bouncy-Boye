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
import UIKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Commonly Used Nodes
    var backgroundNode: SKNode!
    var midgroundNode: SKNode!
    var foregroundNode: SKNode!
    var hudNode: SKNode!
    var player: SKNode!
    var window: UIWindow?
    
    // Node for tap to start image
    let tapToStartNode = SKSpriteNode(imageNamed: "TapToStart")
    
    // Initialization of class variables
    var scaleFactor: CGFloat!
    
    var endLevelY = 0
    var previousPlatformY = 0
    var previousPointsY = 300
    var previousFlareY = 200
    var previousEnemyY = 1000
    var maxPlayerY: Int!
    
    var nodeLevel = 1
    var nextNodeLevelY = 1000.0
    var flareLevel = 1
    var nextFlareLevelY = 1000.0
    var difficultyLevel = 1
    var nextLevelY:Double = 1000.0
    
    var labelScore: SKLabelNode!
    var labelPointItems: SKLabelNode!
    
    var gameOver = false
    
    // Accelerometer
    let motionManager = CMMotionManager()
    var xAcceleration: CGFloat = 0.0
    
    //Names of images used in game
    var PLAYER_IMAGE = "dog"
    var POINT_ITEM_IMAGE = "Ball"
    var POINT_ITEM_SPECIAL_IMAGE = "BallSpecial"
    var PLATFORM_IMAGE = "ground_sand"
    var PLATFORM_SPECIAL_IMAGE = "ground_sand_broken"
    var SIDE_FLARE_IMAGE = "cactus"
    var ENEMY_IMAGE = "spinner"
    
    // Required Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // Init that creates initial view of game scene
    // Resets necessary variables and nodes when restarting game
    override init(size: CGSize) {
        super.init(size: size)
        
        maxPlayerY = 80
        GameState.sharedInstance.score = 0
        gameOver = false
        nodeLevel = 1
        nextNodeLevelY = 1000.0
        difficultyLevel = 1
        nextLevelY = 1000.0
        jumpVelocity = 250.0
        PLAYER_IMAGE = GameState.sharedInstance.equippedItem
        
        backgroundColor = SKColor.black
        scaleFactor = self.size.width / 320
        
        backgroundNode = createBackgroundNode()
        addChild(backgroundNode)
        
        midgroundNode = SKNode()
        addChild(midgroundNode)
        
        foregroundNode = SKNode()
        addChild(foregroundNode)
        
        createGamePieces(type: "platform")
        createGamePieces(type: "point")
        createGamePieces(type: "enemy")
        
        player = createPlayer()
        foregroundNode.addChild(player)
        
        hudNode = SKNode()
        tapToStartNode.position = CGPoint(x: self.size.width / 2, y: 180.0)
        
        let pointCounterImage = SKSpriteNode(imageNamed: POINT_ITEM_IMAGE)
        pointCounterImage.position = CGPoint(x: 25, y: self.size.height-30)
        hudNode.addChild(pointCounterImage)
        
        // Creates labels in the game's UI for the score and points
        labelPointItems = SKLabelNode(fontNamed: "ChalkboardSE-Bold")
        labelPointItems.fontSize = 24
        labelPointItems.fontColor = SKColor.black
        labelPointItems.position = CGPoint(x: 50, y: self.size.height-40)
        labelPointItems.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        labelPointItems.text = "X\(GameState.sharedInstance.pointItems)"
        hudNode.addChild(labelPointItems)
        
        labelScore = SKLabelNode(fontNamed: "ChalkboardSE-Bold")
        labelScore.fontSize = 24
        labelScore.fontColor = SKColor.black
        labelScore.position = CGPoint(x: self.size.width-20, y: self.size.height-40)
        labelScore.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.right
        labelScore.text = "0"
        hudNode.addChild(labelScore)
        
        motionManager.accelerometerUpdateInterval = 0.2
        
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!, withHandler: {_,_ in
            if let accelerometerData = self.motionManager.accelerometerData {
                let acceleration = accelerometerData.acceleration
                self.xAcceleration = (CGFloat(acceleration.x)*0.75) + (self.xAcceleration * 0.25)
            }
        })
        
        hudNode.addChild(tapToStartNode)
        addChild(hudNode)
        
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -2.0)
        physicsWorld.contactDelegate = self
    }
    
    // Create a node to be used in the midground
    // Returns SKNode
    func createMidgroundNode() -> SKNode {
        
        let mgNode = SKNode()
        let sprite = SKSpriteNode(imageNamed: SIDE_FLARE_IMAGE)
        var anchor: CGPoint!
        var xPosition: CGFloat!
        previousFlareY += Int(100+arc4random_uniform(101))
        
        let r = arc4random_uniform(2)
        if r > 0 {
            sprite.zRotation = CGFloat(M_PI_2)
            anchor = CGPoint(x: 1.0, y: 0.5)
            xPosition = self.size.width - (sprite.size.height / 2)
        }
        else {
            sprite.zRotation = CGFloat(-M_PI_2)
            anchor = CGPoint(x: 0.0, y: 0.5)
            xPosition = 0.0 + (sprite.size.height / 2)
        }
        
        sprite.anchorPoint = anchor
        sprite.position = CGPoint(x: xPosition, y: CGFloat(previousFlareY))
        mgNode.addChild(sprite)
        mgNode.name = "NODE_MIDGROUND"
        
        return mgNode
        
    }
    
    // Create a node to be used in the background
    // Returns SKNode
    func createBackgroundNode() -> SKNode {
        
        let bgNode = SKNode()
        let ySpacing = 64.0 * scaleFactor
        
        let node = SKSpriteNode(imageNamed: "bg")
        node.setScale(scaleFactor)
        node.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        node.position = CGPoint(x: self.size.width / 2, y: ySpacing * CGFloat(nodeLevel-1))
        bgNode.name = "NODE_BACKGROUND"
        bgNode.addChild(node)
        
        return bgNode
        
    }
    
    // Run a sequence that creates a set of all game pieces to make the game scroll infinitely
    func createGamePieces(type: String) {
    
        let create = SKAction.run { [unowned self] in
            
            switch(type) {
            case "point":
                self.createPointItems()
                break
            case "platform":
                self.createPlatforms()
                let newMidNode = self.createMidgroundNode()
                self.midgroundNode.addChild(newMidNode)
                break
            case "enemy":
                self.createEnemy()
                break
            default:
                break
            }
        }
        
        let wait = SKAction.wait(forDuration: 0.1)
        let sequence = SKAction.sequence([create, wait])
        let repeatSequence = SKAction.repeat(sequence, count: 5)
        
        run(repeatSequence)
    
    }
    
    // Create the player with appropriate physics body
    // Returns SKNode
    func createPlayer() -> SKNode {
        let playerNode = SKNode()
        playerNode.position = CGPoint(x: self.size.width / 2, y: 80.0)
        
        let sprite = SKSpriteNode(imageNamed: PLAYER_IMAGE)
        sprite.setScale(0.35)
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
    
    // Creates a new enemy dot at a random position
    func createEnemy() {
        
    
        let randX = GKRandomDistribution(lowestValue: Int(self.frame.minX) + 40, highestValue: Int(self.frame.maxX) - 100)
        let randY = GKRandomDistribution(lowestValue: previousEnemyY + 200, highestValue: previousEnemyY + 700)
        
        let yPosition = randY.nextInt()
        previousEnemyY = yPosition
        
        let node = SKNode()
        let thePosition = CGPoint(x: randX.nextInt(), y: yPosition)
        node.position = thePosition
        
        let sprite = SKSpriteNode(imageNamed: ENEMY_IMAGE)
        sprite.setScale(0.8)
        node.addChild(sprite)
        node.physicsBody = SKPhysicsBody(circleOfRadius: sprite.size.width / 2)
        node.physicsBody?.isDynamic = false
        node.name = "NODE_ENEMY"
        
        foregroundNode.addChild(node)
    
    }
    
    // Create a random number of point items between 0 and 5 in a 500 height range
    func createPointItems() {
        
        let randX = GKRandomDistribution(lowestValue: Int(self.frame.minX) + 20, highestValue: Int(self.frame.maxX) - 80)
        let randY = GKRandomDistribution(lowestValue: previousPointsY, highestValue: previousPointsY + 100)
        let randPointsInArea = Int(arc4random_uniform(2))
        
        for _ in 0...randPointsInArea {
            let randomType = randomNumber(probabilities: [0.8, 0.2])
            let type = PointItemType(rawValue: randomType)
            let yPosition = CGFloat(randY.nextInt())
            let xPosition = CGFloat(randX.nextInt())
            let pointItemNode = createPointAtPosition(position: CGPoint(x: xPosition, y: yPosition), type: type!)
            foregroundNode.addChild(pointItemNode)
        }
        
        previousPointsY += 100
        
    }
    
    // Create a platform at a random x and random reachable y
    func createPlatforms() {
        
        let scaleDifficulty:CGFloat = (0.1 * (CGFloat)(nodeLevel))
        let randX = GKRandomDistribution(lowestValue: Int(self.frame.minX) + 40, highestValue: Int(self.frame.maxX) - 100)
        let xPosition = CGFloat(randX.nextInt())
        
        let randY = GKRandomDistribution(lowestValue: previousPlatformY + (Int)(CGFloat(0.2 + (0.04*Double(nodeLevel))) * jumpVelocity),
                                         highestValue: previousPlatformY + (Int)(CGFloat(0.35 + (0.04*Double(nodeLevel))) * jumpVelocity))
        let yPosition = CGFloat(randY.nextInt())
        
        previousPlatformY = Int(yPosition)
        
        // difficulty level dtermines likelyhood of breakable platforms
        let randomType = randomNumber(probabilities: [Double(1 - scaleDifficulty), Double(scaleDifficulty)])
        let type = PlatformType(rawValue: randomType)
        
        let platformNode = createPlatformAtPosition(position: CGPoint(x: xPosition, y: yPosition), type: type!)
        foregroundNode.addChild(platformNode)
        
    }
    
    // Select a random integer from array containing probabilities
    // Probabilities reflect the chance of their index being chosen
    // Returns Int
    func randomNumber(probabilities: [Double]) -> Int {
        
        let sum = probabilities.reduce(0, +)
        let rnd = sum * Double(arc4random_uniform(UInt32.max)) / Double(UInt32.max)
        
        var accum = 0.0
        
        for (i, p) in probabilities.enumerated() {
            accum += p
            if rnd < accum {
                return i
            }
        }
        
        return (probabilities.count - 1)
        
    }
    
    // Start game if touch to start message is displayed otherwise do nothing
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if player.physicsBody!.isDynamic {
            return
        }
        
        tapToStartNode.removeFromParent()
        player.physicsBody?.isDynamic = true
        player.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: 35.0))       
    }
    
    // Given a position and type creates a point item of specified type at specified location
    // Returns PointNode
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
        sprite.setScale(1.5)
        node.addChild(sprite)
        node.physicsBody = SKPhysicsBody(circleOfRadius: sprite.size.width / 2)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = CollisionCategoryBitmask.PointItem
        node.physicsBody?.collisionBitMask = 0
        
        return node
        
    }
    
    // Given a position and type creates a platform of specified type at specified location
    // Returns PlatformNode
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
        sprite.setScale(0.2)
        node.addChild(sprite)
        
        node.physicsBody = SKPhysicsBody(rectangleOf: sprite.size)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = CollisionCategoryBitmask.Platform
        node.physicsBody?.collisionBitMask = 0
        
        return node
    }
    
    // When player makes contact with a GameObject perform an action and check to see what object it was
    // If the object is a point item, reflect that in the score/UI
    func didBegin(_ contact: SKPhysicsContact) {
        
        if (contact.bodyA.node?.name == "NODE_ENEMY" || contact.bodyB.node?.name == "NODE_ENEMY") {
            endGame()
            return
        }
        
        var updateHUD = false
        let whichNode = (contact.bodyA.node != player) ? contact.bodyA.node : contact.bodyB.node
        let pointItemNode = whichNode as! GameObjectNode
        
        updateHUD = pointItemNode.collisionWithPlayer(player: player)
        
        if updateHUD {
            labelScore.text = "\(GameState.sharedInstance.score)"
            labelPointItems.text = "X \(GameState.sharedInstance.pointItems)"
        }
    }
    
    // Series of checks called as the player moves up the screen
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
        
        foregroundNode.enumerateChildNodes(withName: "NODE_ENEMY", using: {
            (node, stop) in
            let enemy = node
            if enemy.position.y < self.player.position.y - 300.0 {
                enemy.removeFromParent()
            }
        })
        
        if player.position.y > 200.0 {
            midgroundNode.position = CGPoint(x: 0.0, y: -((player.position.y - 200.0)))
            foregroundNode.position = CGPoint(x: 0.0, y: -(player.position.y - 200.0))
        }
        
        if Int(player.position.y) < maxPlayerY - 800 {
            endGame()
        }
        
        // increase difficulty when player reaches nextLevelY
        if ((Double)(maxPlayerY) > nextLevelY && difficultyLevel < 10) {
            difficultyLevel += 1
            nextLevelY += (Double)(difficultyLevel * 1000)
            jumpVelocity += 30.0
        }
        
        // increase node create difficulty
        if ((Double)(previousPlatformY) > nextNodeLevelY && nodeLevel < 10) {
            nodeLevel += 1
            nextNodeLevelY += (Double)(nodeLevel * 1000)
            
            // Set images for game pieces based on level
            switch (nodeLevel) {
            case 1,2:
                PLATFORM_IMAGE = "ground_sand"
                PLATFORM_SPECIAL_IMAGE = "ground_sand_broken"
                break
            case 3,4:
                PLATFORM_IMAGE = "ground_grass"
                PLATFORM_SPECIAL_IMAGE = "ground_grass_broken"
                break
            case 5,6:
                PLATFORM_IMAGE = "ground_wood"
                PLATFORM_SPECIAL_IMAGE = "ground_wood_broken"
                break
            case 7,8:
                PLATFORM_IMAGE = "ground_stone"
                PLATFORM_SPECIAL_IMAGE = "ground_stone_broken"
                break
            case _ where nodeLevel > 8:
                PLATFORM_IMAGE = "ground_snow"
                PLATFORM_SPECIAL_IMAGE = "ground_snow_broken"
                break
            default:
                break
            }
        }
        
        // change flare of midground
        if ((Double)(previousFlareY) > nextFlareLevelY && flareLevel < 10) {
            flareLevel += 1
            nextFlareLevelY += (Double)(flareLevel * 1000)
            
            switch (flareLevel) {
            case 1,2:
                SIDE_FLARE_IMAGE = "cactus"
                break
            case 3,4:
                SIDE_FLARE_IMAGE = "grass"
                break
            case 5,6:
                SIDE_FLARE_IMAGE = "branch"
                break
            case 7,8:
                SIDE_FLARE_IMAGE = "grass_brown"
                break
            case _ where flareLevel > 8:
                SIDE_FLARE_IMAGE = "spike"
                break
            default:
                break
            }
        }
        
        // If the player is approaching the top of generated objects, generate more
        if Int(player.position.y + 500.0) >= previousPlatformY {
            createGamePieces(type: "platform")
        }
        
        if Int(player.position.y + 500.0) >= previousPointsY {
            createGamePieces(type: "point")
        }
        
        if Int(player.position.y + 500.0) >= previousEnemyY {
            createGamePieces(type: "enemy")
        }
    }
    
    // End the game, save the state of the game, show end game scene
    func endGame() {
        
        gameOver = true
        
        GameState.sharedInstance.saveState()
        
        let reveal = SKTransition.fade(withDuration: 0.5)
        let endGameScene = EndGameScene(size: self.size)
        self.view!.presentScene(endGameScene, transition: reveal)
    }
    
    // Called by accelerometer to move player across X axis
    // Will place player on opposite side of screen when leaving the screen
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









