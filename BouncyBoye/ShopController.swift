//
//  ShopController.swift
//  BouncyBoye
//
//  Created by admin on 5/5/18.
//  Copyright © 2018 Cole Hassett. All rights reserved.
//

import UIKit

class ShopController: UIViewController {
    
    var balance = 0
    
    // labels for the shop item's prices
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var dogLabel: UILabel!
    @IBOutlet weak var duckLabel: UILabel!
    @IBOutlet weak var monkeyLabel: UILabel!
    @IBOutlet weak var snakeLabel: UILabel!
    @IBOutlet weak var elephantLabel: UILabel!
    @IBOutlet weak var penguinLabel: UILabel!
    
    // buttons for the shop ui
    @IBAction func dogBtn(_ sender: Any) { buyItem(name: "dog") }
    @IBAction func duckBtn(_ sender: Any) { buyItem(name: "duck") }
    @IBAction func monkeyBtn(_ sender: Any) { buyItem(name: "monkey") }
    @IBAction func snakeBtn(_ sender: Any) { buyItem(name: "snake") }
    @IBAction func elephantBtn(_ sender: Any) { buyItem(name: "elephant") }
    @IBAction func penguinBtn(_ sender: Any) { buyItem(name: "penguin") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateLabels()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // updates the values of all of the labels
    func updateLabels() {
        // set item prices labels
        setLabel(name: "dog", label: dogLabel)
        setLabel(name: "duck", label: duckLabel)
        setLabel(name: "monkey", label: monkeyLabel)
        setLabel(name: "snake", label: snakeLabel)
        setLabel(name: "elephant", label: elephantLabel)
        setLabel(name: "penguin", label: penguinLabel)
        
        // set balance label
        balance = GameState.sharedInstance.pointItems
        balanceLabel.text = String(balance)
    }
    
    // setLabel is a helper fucntion for updateLabels that finds the correct value for
    // a given item name and sets it to the supplied ui label
    func setLabel(name:String, label:UILabel) {
        let animals = GameState.sharedInstance.animals
        
        // if the currently equipped item is this one
        if (GameState.sharedInstance.equippedItem == name) {
            label.text = "equipped"
            label.font = UIFont(name:"HelveticaNeue-Bold", size: 16.0)
        } else {
            // find item in gamestate list
            for animal in animals {
                if (animal.name == name) {
                    label.font = UIFont(name:"HelveticaNeue", size: 16.0)
                    
                    // if the item is owned
                    if animal.owned {
                        label.text = "owned"
                    }
                    // if the item hasn't been bought
                    else {
                        label.text = String(animal.price)
                    }
                }
            }
        }
        
    
    }
    
    // buyItem takes an item's name and price, and attempts to buy it.
    func buyItem(name: String) {
        // get the animal information
        let animals = GameState.sharedInstance.animals
        var price = 0
        var owned = false
        for animal in animals {
            if (animal.name == name) {
                price = animal.price
                owned = animal.owned
            }
        }
        
        // buy the item
        if (!owned && canAfford(price: price)) {
            spendMoney(price: price)
            unlockCharacter(name: name)
            owned = true
        }
        
        // always equip item if owned
        if (owned) {
            GameState.sharedInstance.updateEquippedItem(name: name)
        }
        
        updateLabels()
    }
    
    // canAfford determines
    func canAfford(price: Int)->Bool {
        print("balance: " + String(balance))
        print("price: " + String(price))
        if (balance >= price) {
            return true
        } else {
            return false
        }
    }
    
    // reduces the user's balance when they spend money
    func spendMoney(price: Int) {
        GameState.sharedInstance.spendPoints(points: price)
        balance = GameState.sharedInstance.pointItems
        balanceLabel.text = String(balance)
    }
    
    // unlocks character
    func unlockCharacter(name: String) {
        var animals = GameState.sharedInstance.animals
        var thisAnimal: GameState.Animal = animals[0]
        var index = -1
        
        // find character in game list
        for var i in 0..<animals.count {
            if (animals[i].name == name) {
                index = i
                // set that animal to be owned
                thisAnimal = animals[index]
                thisAnimal.owned = true
            }
        }
        
        // if the animal was found, update it in the gamestate to be owned
        if (index > -1) {
            animals.remove(at: index)
            animals.append(thisAnimal)
        }
        
        GameState.sharedInstance.updateAnimals(newAnimals:animals)
    }

}
