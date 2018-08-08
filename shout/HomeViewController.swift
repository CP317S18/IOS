//
//  HomeViewController.swift
//  shout
//
//  Created by Greg Murray on 2018-07-05.
//  Copyright © 2018 wlu. All rights reserved.
//
//hi
import UIKit
import CoreBluetooth

class HomeViewController: UIViewController, ConnectionDelegate, UITextFieldDelegate, CBCentralManagerDelegate {
    
    
    //Core Bluetooth Manager
    var BLManager:CBCentralManager!
    
    var client: BluetoothClient = BluetoothClient.getInstance()

    //User Defaults to persist Username
    let userDefaults = UserDefaults.standard
    let maxLength: Int = 30
    let bluetoothAlert: UIAlertController = UIAlertController(title: "Please Enable Bluetooth", message: "In order to use this app properly, you must have bluetooth enabled.", preferredStyle: .alert)
    var alertShowing: Bool = false
    
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
        
        BLManager           = CBCentralManager()
        BLManager.delegate  = self
        
        // Set shout to connected count
        self.shoutCount.text = "\(client.getConnectedCount())"
        
        //give usernameField a delegate so you can close keyboard on return
        self.usernameField.delegate = self
        //Fetch Saved Username and Set
        let savedUsername = userDefaults.object(forKey: "username") as? String
        if (savedUsername != nil){
            usernameField.text = savedUsername
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        
        
        self.bluetoothAlert.addAction(UIAlertAction(title: "Enable", style: .default, handler: {action in
            //This could possibly get us rejected from the app store because of ios 11, only time will tell
            //UIApplication.shared.open(URL(string:"App-Prefs:root=Bluetooth")!, options: [:], completionHandler: nil)
            UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
        }))
        self.bluetoothAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is On.")
            if self.alertShowing{
                self.dismiss(animated: true, completion: nil)
            }
            break
        case .poweredOff:
            print("Bluetooth is off.")
            self.alertShowing = true
            self.present(self.bluetoothAlert, animated: true)
        break
        case .resetting:
            break
        case .unauthorized:
            break
        case .unsupported:
            break
        case .unknown:
            break
        default:
            break
        }

    }
    
    // Close Keyboard on username return
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        usernameField.resignFirstResponder()
        return false
    }
    
    @IBAction func maxLengthCheck(_ sender: Any) {
        if ((usernameField.text?.count)! > self.maxLength) {
            usernameField.deleteBackward()
        }
    }
    @objc func keyboardWillChange(notification: Notification){
        guard let keyboardRect = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        if notification.name == Notification.Name.UIKeyboardWillShow || notification.name == Notification.Name.UIKeyboardWillChangeFrame{
            
            view.frame.origin.y = -keyboardRect.height
        }else {
            view.frame.origin.y = 0
        }
        
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

