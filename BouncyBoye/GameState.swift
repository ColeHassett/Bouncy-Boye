//
//  GameState.swift
//  BouncyBoye
//
//  Created by Cole Hassett on 5/4/18.
//  Copyright © 2018 Cole Hassett. All rights reserved.
//

import Foundation

class GameState {
    
    // Game variables
    var score: Int
    var highScore: Int
    var pointItems: Int
    var equippedItem: String
    var animals: Array<Animal>
    
    // Singleton creation
    class var sharedInstance: GameState {
        struct Singleton {
            static let instance = GameState()
        }
        return Singleton.instance
    }
    
    struct Animal {
        var name: String, price: Int, owned: Bool
        init(name: String, price: Int, owned: Bool) {
            self.name   = name
            self.price  = price
            self.owned  = owned
        }
    }
    

    // Initialize all variables and user defaults for first time use
    init() {
        
        score = 0
        highScore = 0
        pointItems = 0
        equippedItem = "dog"
        
        // initialize the animal items array
        var dog = Animal(name: "dog", price: 5, owned: true)
        var duck = Animal(name: "duck", price: 50, owned: false)
        var monkey = Animal(name: "monkey", price: 100, owned: false)
        var snake = Animal(name: "snake", price: 200, owned: false)
        var elephant = Animal(name: "elephant", price: 300, owned: false)
        var penguin = Animal(name: "penguin", price: 500, owned: false)
        var animalArray = [dog, duck, monkey, snake, elephant, penguin]
        
        animals = animalArray
        
        let defaults = UserDefaults.standard
        highScore = defaults.integer(forKey: "highScore")
        pointItems = defaults.integer(forKey: "pointItems")
    }
    
    // Save all the persistent variables to user defaults
    func saveState() {
        
        highScore = max(score, highScore)
        let defaults = UserDefaults.standard
        defaults.set(highScore, forKey: "highScore")
        defaults.set(pointItems, forKey: "pointItems")
        
        UserDefaults.standard.synchronize()
    }
    
    // changes which item is equipped
    func updateEquippedItem(name:String) {
        equippedItem = name
        // TODO: change character's image to new name
    }
    
    // setter for animals field
    func updateAnimals(newAnimals:Array<Animal>) {
        animals = newAnimals
    }
    
    // assumes the cost is affordable, decrements the score
    func spendPoints(points:Int) {
        pointItems -= points
    }
    
}
