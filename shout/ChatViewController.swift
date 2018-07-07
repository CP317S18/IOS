//
//  ChatViewController.swift
//  shout
//
//  Created by Greg Murray on 2018-07-05.
//  Copyright © 2018 wlu. All rights reserved.
//

import UIKit
import Foundation

class ChatViewController: UIViewController, MessageRecievedDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    /*
     
     View Layout Sections:
     1. Variable declaration and outlets
     2. View DidLoad
     3. Core Message Functions
     4. Keyboard Control Functions
     5. Table View functions
 
    */
    
    var client: BluetoothClient = BluetoothClient.getInstance()
    
    
    //User Defaults to persist Username
    let userDefaults = UserDefaults.standard
    var username: String?
    
    //Store Last Connected and disconnected to avoid spamming
    var lastConnected: String = ""
    var lastDisconnected: String = ""
    
    // Outlets attached to StoryBoard
    @IBOutlet weak var keyboardConstraint: NSLayoutConstraint!
    @IBOutlet var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageField: UITextField!
    @IBOutlet weak var messageTableView: UITableView!
    
    @IBOutlet weak var navBarItem: UINavigationItem!
    
    //Array Containing the Messages
    var messages: NSMutableArray = []
    var colourMap: [String:String] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Initial Bluetooth Client Setup
        client.register(messageDelegate: self)
        
        //Fetches username from userdefaults
        self.username = userDefaults.object(forKey: "username") as? String
        
        //Set Delegate for field control
        self.messageField.delegate = self
        
        //TableView Init
        messageTableView.delegate = self
        messageTableView.dataSource = self
        messageTableView.estimatedRowHeight = 25
        messageTableView.tableFooterView = UIView()
        messageTableView.reloadData()
        
        //Adds Observer for when Keyboard is shown and when keyboard will hide
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        //Recognizes tap on messages and closes keyboard
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        //Listener for Back Button Tapped
        navBarItem.leftBarButtonItem = UIBarButtonItem(title: "Leave", style: .plain, target: self, action: #selector(leaveChat))
        var title = "# people shouting"
        if(client.getConnectedCount() == 0){
            title = "you are alone"
        }else{
            title = "\(client.getConnectedCount())" + " people shouting"
            
        }
        navBarItem.title = title
        
        self.alertChat(type: messageType.connection)
    }

    
    @objc func leaveChat(){
        //dismiss(animated: true, completion: nil)
        self.alertChat(type: messageType.disconnection)
        let transition: CATransition = CATransition()
        transition.duration = 0.5
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        transition.type = kCATransitionReveal
        transition.subtype = kCATransitionFromLeft
        self.view.window!.layer.add(transition, forKey: nil)
        self.dismiss(animated: false, completion: nil)
    }
    
    
    /*
 
     Messaging Functions
     
     */
    
    //This Function handles when a Message is Recieved
    func onMessageReceived(message: ChatMessage) {
        print("Delegate Message recieived")
        
        
        switch message.type{
            
        //Is Normal Message
        case messageType.message.rawValue:
            self.messages.add(message)
            self.addRowToTable()
            
        //Is Connected Message
        case messageType.connection.rawValue:
            
            //Check if last user connected
            if (self.lastConnected != message.username){
                self.lastConnected = message.username
                self.messages.add(message)
                self.addRowToTable()
            }
        
        //Is Disconnected Message
        case messageType.disconnection.rawValue:
            
            //Check if last user disconnected
            if (self.lastDisconnected != message.username){
                self.lastDisconnected = message.username
                self.messages.add(message)
                self.addRowToTable()
            }
            
        //Default case, shouldnt ever happen?
        default:
            self.messages.add(message)
            self.addRowToTable()
            
        }
    }
    

    //When the "Send" button on they keyboard is pressed
    @IBAction func messagePrimaryActionTriggered(_ sender: Any) {
        if self.messageField.text!.isEmpty {
            return
        }
        self.sendMessage()
    }
    
    //Sends Message to Chat
    private func sendMessage() {
        print("Send Message from View Controller Called")
        let message: ChatMessage = ChatMessage()
        message.username = self.username!
        message.content = self.messageField.text!
        message.type = messageType.message.rawValue
        
        client.sendMessage(message)
         
        self.messageField.text = ""
        self.messages.add(message)
        
        self.addRowToTable()
    }
    
    //Sends new message alerting when a new user has joined or left
    //Specify either deviceType.connected/disconnected
    func alertChat(type: messageType){
        
        let message: ChatMessage = ChatMessage()
        
        message.username = self.username!
        message.content = ""
        message.type = type.rawValue
        
        client.sendMessage(message)
        
        self.messages.add(message)
        
        self.addRowToTable()
    }

    
    func getMessageColour(username: String) -> UIColor{
        // Check if the username is stored in colour Map
        
        if self.colourMap.keys.contains(username){
            
            return UIColor(hex: colourMap[username]!)
            
        }else{
            
            //If not, randomly find an index from websafeColours
            var colourIndex = arc4random_uniform(UInt32(webSafeColours.count))
            var colour = webSafeColours[Int(colourIndex)]
            
            //Edge case if colour is being used
            while(colourBeenUsed(colour: colour)){
                print("Colour Been Used")
                colourIndex = arc4random_uniform(UInt32(webSafeColours.count))
                colour = webSafeColours[Int(colourIndex)]
            }
            colourMap[username] = colour
            return UIColor(hex: colour)
            
            
        }
    }
    
    // Checks if Colour has been used before
    func colourBeenUsed(colour: String) -> Bool{
        for (_, userColour) in self.colourMap{
            if(userColour == colour){
                return true
            }
        }
        return false
    }
    
    
    /*
 
     Keyboard Control Functions
     
    */
    
    @objc func keyboardWillShow(_ notification: Notification) {
        var keyboardInfo = notification.userInfo!
        let keyboardFrameBegin = keyboardInfo[UIKeyboardFrameEndUserInfoKey]
        let frame: CGRect = (keyboardFrameBegin! as AnyObject).cgRectValue
        var padding: CGFloat = 0.0;
        if #available(iOS 11, *) {
            padding = self.view.safeAreaInsets.bottom;
        }
        
        self.keyboardConstraint.constant = frame.size.height - padding
        UIView.animate(withDuration: 0.5, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
        
        self.adjustTableSize()
        self.moveToBottom()
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        self.keyboardConstraint.constant = 0
        
        UIView.animate(withDuration: 0.5, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
        
        self.adjustTableSize()
    }
    
    @objc func dismissKeyboard() {
        
        view.endEditing(true)
    }
    
    /*
 
    Table View Functions
 
    */
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    //handles the rendering of the data in the cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath)
        
        let userLabel = cell.contentView.viewWithTag(1000) as! UILabel
        let messageLabel = cell.contentView.viewWithTag(1001) as! UILabel
        let message: ChatMessage = self.messages.object(at: indexPath.item) as! ChatMessage
        
        
        switch message.type{
        case messageType.message.rawValue:
            userLabel.text = message.username
            userLabel.textColor = getMessageColour(username: message.username)
            messageLabel.text = message.content
            messageLabel.textColor = UIColor.black
            messageLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
            messageLabel.numberOfLines = 0
            messageLabel.textAlignment = NSTextAlignment.left
        case messageType.connection.rawValue:
            userLabel.text = ""
            messageLabel.text = "\(message.username) has joined chat"
            messageLabel.textColor = UIColor.lightGray
            messageLabel.textAlignment = NSTextAlignment.center
        case messageType.disconnection.rawValue:
            userLabel.text = ""
            messageLabel.text = "\(message.username) has left chat"
            messageLabel.textColor = UIColor.lightGray
            messageLabel.textAlignment = NSTextAlignment.center
        default:
            userLabel.text = message.username
            messageLabel.text = message.content
        }
        return cell
    }
    
    func moveToBottom() {

        if messages.count > 0  {
            
            let indexPath = IndexPath(row: messages.count - 1, section: 0)
            
            messageTableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
        }
    }
    
    func adjustTableSize(){
        var frame: CGRect = self.messageTableView.frame
        frame.size.height = self.messageTableView.contentSize.height
        self.messageTableView.frame = frame
    }
    
    func addRowToTable(){
        self.messageTableView.beginUpdates()
        let indexPath:IndexPath = IndexPath(row:(self.messages.count - 1), section:0)
        self.messageTableView.insertRows(at: [indexPath], with: UITableViewRowAnimation.bottom)
        self.messageTableView.endUpdates()
        self.messageTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        self.adjustTableSize()
        
        
    }
}

extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 0
        
        var rgbValue: UInt64 = 0
        
        scanner.scanHexInt64(&rgbValue)
        
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        
        self.init(
            red: CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue: CGFloat(b) / 0xff, alpha: 1
        )
    }
}
