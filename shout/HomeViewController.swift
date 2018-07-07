//
//  HomeViewController.swift
//  shout
//
//  Created by Greg Murray on 2018-07-05.
//  Copyright © 2018 wlu. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController, ConnectionDelegate, UITextFieldDelegate {
    
    var client: BluetoothClient = BluetoothClient.getInstance()
    //User Defaults to persist Username
    let userDefaults = UserDefaults.standard
    
    //UI Variables
    @IBOutlet var usernameField: UITextField!
    @IBOutlet weak var shoutCount: UILabel!
    
    //UI Actions
    @IBAction func enterChat(_ sender: Any) {
        if self.usernameField.text!.isEmpty {
            //Display some sort of error message or prompt to enter username
            return
        }else{
            //Fetch saved username from userDefaults
            let savedUsername = userDefaults.object(forKey: "username") as? String
            
            //No Username Saved At all
            if(savedUsername == nil){
                userDefaults.set(usernameField.text, forKey: "username")
            }else{
                
                // New Username provided in Username Field
                if (savedUsername != usernameField.text){
                    userDefaults.set(usernameField.text, forKey: "username")
                }
                
            }
            
            //Go to Chat View
            performSegue(withIdentifier: "goToChatSegue", sender: (Any).self)
            
        }
    }
    
    //On Load Function
    override open func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Get Client instance and add Connection listener
        client = BluetoothClient.getInstance()
        client.register(connectionDelegate: self)
        
        // Set shout to connected count
        self.shoutCount.text = "\(client.getConnectedCount())"
        
        //give usernameField a delegate so you can close keyboard on return
        self.usernameField.delegate = self
        
        //Fetch Saved Username and Set
        let savedUsername = userDefaults.object(forKey: "username") as? String
        if (savedUsername != nil){
            usernameField.text = savedUsername
        }
    }
    
    // Close Keyboard on username return
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func deviceConnected() {
        print("Delegate Device Connected")
    }
    
    func deviceLost() {
        print("Delegate Lost Device")
        
    }
    
    func numberOfDevicesConnectedChanged(count: Int) {
        print("Device Connection Changed: \(count)")
        self.shoutCount.text = "\(count)"
    }
}

