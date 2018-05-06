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
    var previousPlatformY = 200
    var previousPointsY = 300
    var maxPlayerY: Int!
    
    var nodeLevel = 1
    var nextNodeLevelY = 1000.0
    var difficultyLevel = 1
    var nextLevelY:Double = 1000.0
    
    var labelScore: SKLabelNode!
    var labelPointItems: SKLabelNode!
    var labelLevel: SKLabelNode!
    var labelJump: SKLabelNode!
    
    var gameOver = false
    
    let motionManager = CMMotionManager()
    var xAcceleration: CGFloat = 0.0
    
    var PLAYER_IMAGE = "dog"
    var POINT_ITEM_IMAGE = "Ball"
    var POINT_ITEM_SPECIAL_IMAGE = "BallSpecial"
    var PLATFORM_IMAGE = "ground_sand"
    var PLATFORM_SPECIAL_IMAGE = "ground_sand_broken"
    var SIDE_FLARE_IMAGE = "cactus"
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        
        print("init")
        
        maxPlayerY = 80
        GameState.sharedInstance.score = 0
        gameOver = false
        nodeLevel = 1
        nextNodeLevelY = 1000.0
        difficultyLevel = 1
        nextLevelY = 1000.0
        jumpVelocity = 250.0
        
        backgroundColor = SKColor.black
        scaleFactor = self.size.width / 320
        backgroundNode = createBackgroundNode()
        addChild(backgroundNode)
        
        foregroundNode = SKNode()
        addChild(foregroundNode)
        
        createGamePieces()
        
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
    
    func createBackgroundNode() -> SKNode {
        
        let backgroundNode = SKNode()
        let ySpacing = 64.0 * scaleFactor
        
        let node = SKSpriteNode(imageNamed: "bg")
        node.setScale(scaleFactor)
        node.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        node.position = CGPoint(x: self.size.width / 2, y: ySpacing * CGFloat(nodeLevel-1))
        backgroundNode.addChild(node)
        
        return backgroundNode
        
    }
    
    func createGamePieces() {
    
        let create = SKAction.run { [unowned self] in
            self.createPlatforms()
            self.createPointItems()
            let newNode = self.createBackgroundNode()
            self.backgroundNode.addChild(newNode)
        }
        
        let wait = SKAction.wait(forDuration: 0.1)
        let sequence = SKAction.sequence([create, wait])
        let repeatSequence = SKAction.repeat(sequence, count: 5)
        
        run(repeatSequence)
    
    }
    
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
    
    func createPointItems() {
        
        let randX = GKRandomDistribution(lowestValue: Int(self.frame.minX) + 20, highestValue: Int(self.frame.maxX) - 80)
        let randY = GKRandomDistribution(lowestValue: previousPointsY, highestValue: previousPointsY + 500)
        let randPointsInArea = Int(arc4random_uniform(6))
        
        for _ in 0...randPointsInArea {
            let randomType = randomNumber(probabilities: [0.8, 0.2])
            let type = PointItemType(rawValue: randomType)
            let yPosition = CGFloat(randY.nextInt())
            let xPosition = CGFloat(randX.nextInt())
            let pointItemNode = createPointAtPosition(position: CGPoint(x: xPosition, y: yPosition), type: type!)
            foregroundNode.addChild(pointItemNode)
        }
        
        previousPointsY += 500
        
    }
    
    func createPlatforms() {
        
        let scaleDifficulty:CGFloat = (0.1 * (CGFloat)(nodeLevel))
        let randX = GKRandomDistribution(lowestValue: Int(self.frame.minX) + 20, highestValue: Int(self.frame.maxX) - 50)
        let xPosition = CGFloat(randX.nextInt())
        
        let randY = GKRandomDistribution(lowestValue: previousPlatformY + (Int)((0.1 + scaleDifficulty) * jumpVelocity), highestValue: previousPlatformY + (Int)((0.3 + scaleDifficulty) * jumpVelocity))
        let yPosition = CGFloat(randY.nextInt())
        
        previousPlatformY = Int(yPosition)
        
        // difficulty level dtermines likelyhood of breakable platforms
        let randomType = randomNumber(probabilities: [Double(1 - scaleDifficulty), Double(scaleDifficulty)])
        let type = PlatformType(rawValue: randomType)
        
        let platformNode = createPlatformAtPosition(position: CGPoint(x: xPosition, y: yPosition), type: type!)
        foregroundNode.addChild(platformNode)
        
    }
    
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
        player.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: 35.0))
        
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
        sprite.setScale(1.5)
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
        sprite.setScale(0.2)
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
            labelLevel.text = "\(difficultyLevel)"
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
        }
        
        // If the player is approaching the top of generated objects, generate more
        if Int(player.position.y + 500.0) >= previousPlatformY || Int(player.position.y + 500.0) >= previousPointsY {
            createGamePieces()
        }
        
        // Set images for game pieces based on level
        switch (nodeLevel) {
        case 1,2:
            PLATFORM_IMAGE = "ground_sand"
            PLATFORM_SPECIAL_IMAGE = "ground_sand_broken"
            SIDE_FLARE_IMAGE = "cactus"
            break
        case 3,4:
            PLATFORM_IMAGE = "ground_grass"
            PLATFORM_SPECIAL_IMAGE = "ground_grass_broken"
            SIDE_FLARE_IMAGE = "grass"
            break
        case 5,6:
            PLATFORM_IMAGE = "ground_wood"
            PLATFORM_SPECIAL_IMAGE = "ground_wood_broken"
            SIDE_FLARE_IMAGE = "grass_brown"
            break
        case 7,8:
            PLATFORM_IMAGE = "ground_stone"
            PLATFORM_SPECIAL_IMAGE = "ground_stone_broken"
            SIDE_FLARE_IMAGE = "cactus"
            break
        case _ where nodeLevel > 8:
            PLATFORM_IMAGE = "ground_snow"
            PLATFORM_SPECIAL_IMAGE = "ground_snow_broken"
            SIDE_FLARE_IMAGE = "spike"
            break
        default:
            break
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









