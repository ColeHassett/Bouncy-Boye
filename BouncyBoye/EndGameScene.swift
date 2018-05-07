//
//  EndGameScene.swift
//  BouncyBoye
//
//  Created by Cole Hassett on 5/4/18.
//  Copyright © 2018 Cole Hassett. All rights reserved.
//

import SpriteKit

class EndGameScene: SKScene {
    
    // Required init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // Init to show empty screen with labels showing score, currency, high score, and restart
    override init(size: CGSize) {
        super.init(size: size)
        
        backgroundColor = SKColor.black
        
        let pointItem = SKSpriteNode(imageNamed: "Ball")
        pointItem.position = CGPoint(x: 25, y: self.size.height-30)
        addChild(pointItem)
        
        let labelPointItems = SKLabelNode(fontNamed: "ChalkboardSE-Bold")
        labelPointItems.fontSize = 30
        labelPointItems.fontColor = SKColor.white
        labelPointItems.position = CGPoint(x: 50, y: self.size.height-40)
        labelPointItems.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        labelPointItems.text = "X \(GameState.sharedInstance.pointItems)"
        addChild(labelPointItems)
        
        let labelScore = SKLabelNode(fontNamed: "ChalkboardSE-Bold")
        labelScore.fontSize = 60
        labelScore.fontColor = SKColor.white
        labelScore.position = CGPoint(x: self.size.width / 2, y: 300)
        labelScore.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        labelScore.text = "\(GameState.sharedInstance.score)"
        addChild(labelScore)
        
        let labelHighScore = SKLabelNode(fontNamed: "ChalkboardSE-Bold")
        labelHighScore.fontSize = 30
        labelHighScore.fontColor = SKColor.cyan
        labelHighScore.position = CGPoint(x: self.size.width / 2, y: 150)
        labelHighScore.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        labelHighScore.text = "High Score \(GameState.sharedInstance.highScore)"
        addChild(labelHighScore)
        
        let labelRestart = SKLabelNode(fontNamed: "ChalkboardSE-Bold")
        labelRestart.fontSize = 24
        labelRestart.fontColor = SKColor.white
        labelRestart.position = CGPoint(x: self.size.width / 2, y: 50)
        labelRestart.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        labelRestart.text = "Tap Anywhere To Try Again"
        addChild(labelRestart)
        
    }
    
    // Restart the game when user touches screen
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let reveal = SKTransition.fade(withDuration: 0.5)
        let gameScene = GameScene(size: self.size)
        self.view!.presentScene(gameScene, transition: reveal)
    }
    
}

