//
//  GameState.swift
//  BouncyBoye
//
//  Created by Cole Hassett on 5/4/18.
//  Copyright © 2018 Cole Hassett. All rights reserved.
//

import Foundation

class GameState {
    
    var score: Int
    var highScore: Int
    var pointItems: Int
    
    class var sharedInstance: GameState {
        struct Singleton {
            static let instance = GameState()
        }
        return Singleton.instance
    }
    
    init() {
        
        score = 0
        highScore = 0
        pointItems = 0
        
        let defaults = UserDefaults.standard
        highScore = defaults.integer(forKey: "highScore")
        pointItems = defaults.integer(forKey: "pointItems")
    }
    
    func saveState() {
        
        highScore = max(score, highScore)
        let defaults = UserDefaults.standard
        defaults.set(highScore, forKey: "highScore")
        defaults.set(pointItems, forKey: "pointItems")
        
        UserDefaults.standard.synchronize()
    }
    
}
