//
//  ChatViewController.swift
//  shout
//
//  Created by Greg Murray on 2018-07-05.
//  Copyright © 2018 wlu. All rights reserved.
//

import UIKit
import Foundation
import UserNotifications

class ChatViewController: UIViewController, MessageRecievedDelegate, ConnectionDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
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
    var barHeight: CGFloat = 0.0
    var kbHeight: CGFloat = 0.0
    
    let messagePadding: CGFloat = 10.0
    let subUsernamePadding: CGFloat = 20.0
    
    //Store Last Connected and disconnected to avoid spamming
    //var lastConnected: String = ""
    //var lastDisconnected: String = ""
    
    // Outlets attached to StoryBoard
    @IBOutlet weak var keyboardConstraint: NSLayoutConstraint!
    @IBOutlet var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageField: UITextField!
    @IBOutlet weak var messageTableView: UITableView!
    @IBOutlet weak var composeView: UIView!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var numberView: UIView!
    @IBOutlet weak var navBarItem: UINavigationItem!
    
    //Array Containing the Messages
    var messages: NSMutableArray = []
    var colourMap: [String:String] = [:]
    var rectMap: [String: UIBezierPath] = [:]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // UI Navigation Bar: Removes Border Line
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        
        // UI Shouter Bar: Add Drop Shadow
        let shadowPathBar = UIBezierPath(rect: numberView.bounds)
        numberView.clipsToBounds = false
        numberView.layer.shadowColor = UIColor.black.cgColor
        numberView.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        numberView.layer.shadowRadius = 2
        numberView.layer.shadowOpacity = 0.4
        numberView.layer.shadowPath = shadowPathBar.cgPath
    
        
        //Initial Bluetooth Client Setup
        client.register(messageDelegate: self)
        client.register(connectionDelegate: self)
        
        //Fetches username from userdefaults
        self.username = userDefaults.object(forKey: "username") as? String
        
        //Set Delegate for field control
        self.messageField.delegate = self
        
        //TableView Init
        messageTableView.delegate = self
        messageTableView.dataSource = self
        messageTableView.tableFooterView = UIView()
        messageTableView.reloadData()
        
        //Adds Observer for when Keyboard is shown and when keyboard will hide
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        //Observer for when the controller is opened once its already closed
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.openactivity), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        UNUserNotificationCenter.current().requestAuthorization(options:
            [[.alert, .sound, .badge]],
                                    completionHandler: { (granted, error) in
                                    // Handle Error
        })
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        //Recognizes tap on messages and closes keyboard
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        //Listener for Back Button Tapped
        navBarItem.leftBarButtonItem = UIBarButtonItem(title: "Leave", style: .plain, target: self, action: #selector(leaveChat))
        

        var title: String = "# People Shouting"
        if(self.client.getConnectedCount() == 0){
            title = "You are Alone"
        }else{
            title = "\(client.getConnectedCount())" + " People Shouting"
        }
        numberLabel.text = title
        
        
        self.alertChat(type: messageType.connection)
        
        barHeight = UIApplication.shared.statusBarFrame.height +
            self.navigationController!.navigationBar.frame.height
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    @objc func openactivity()  {
        //Clear Notifications
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    @objc func leaveChat(){
        self.alertChat(type: messageType.disconnection)
        let transition: CATransition = CATransition()
        transition.duration = 0.5
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        transition.type = kCATransitionReveal
        transition.subtype = kCATransitionFromLeft
        self.view.window!.layer.add(transition, forKey: nil)
        self.client.unRegister(messageDelegate: self)
        self.client.unRegister(connectionDelegate: self)
        self.dismiss(animated: false, completion: nil)
    }
    
    func numberOfDevicesConnectedChanged(count: Int) {
        var title: String
        if(count == 0){
            title = "You are Alone"
        }else{
            title = "\(count)" + " People Shouting"
        }
        numberLabel.text = title
    }
    /*
 
     Messaging Functions
     
     */
    
    //This Function handles when a Message is Recieved
    func onMessageReceived(message: ChatMessage) {
        let state: UIApplicationState = UIApplication.shared.applicationState
        
        print("Message Received")
        
        switch message.type{
            
        //Is Normal Message
        case messageType.message.rawValue:
            
            if state == .background{
                print("app in background, sending notification")
                messageNotification(message: message)
            }
            
            self.messages.add(message)
            self.addRowToTable()
            
        //Is Connected Message
        case messageType.connection.rawValue:
            
            self.messages.add(message)
            self.addRowToTable()
        
        //Is Disconnected Message
        case messageType.disconnection.rawValue:

            self.messages.add(message)
            self.addRowToTable()
            
        //Default case, shouldnt ever happen?
        default:
            
            self.messages.add(message)
            self.addRowToTable()
            
        }
    }
    

    //When the "Send" button on they keyboard is pressed
    @IBAction func messagePrimaryActionTriggered(_ sender: Any) {
        if self.messageField.text!.trimmingCharacters(in: .whitespaces).isEmpty {
            return
        }
        self.sendMessage()
    }
    
    //Sends Message to Chat
    private func sendMessage() {
        print("Send Message from View Controller Called")
        let message: ChatMessage = ChatMessage()
        message.username = self.username!
        message.uuid = client.getUUID()
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
        message.uuid = client.getUUID()
        
        client.sendMessage(message)
        
        self.messages.add(message)
        
        self.addRowToTable()
    }

    
    func getMessageColour(uuid: String) -> UIColor{
        // Check if the username is stored in colour Map
        
        if self.colourMap.keys.contains(uuid){
            
            return UIColor(hex: colourMap[uuid]!)
            
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
            colourMap[uuid] = colour
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
    
    //Sends Notification to iOS if app is in background mode
    func messageNotification(message: ChatMessage) {
        let content = UNMutableNotificationContent()
        
        if userDefaults.bool(forKey: "NotificationsActive"){
            content.title = "Shout From \(message.username)"
            content.body = message.content
            content.badge = 1
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5,
                                                            repeats: false)
            
            let requestIdentifier = "shoutNotification"
            let request = UNNotificationRequest(identifier: requestIdentifier,
                                                content: content, trigger: trigger)
            
            //Add Notification to iphone
            UNUserNotificationCenter.current().add(request,
                                                   withCompletionHandler: { (error) in
                                                    // Handle error
            })
        }
        
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
        
       
        self.kbHeight = frame.size.height - padding
        self.moveToBottom()
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        self.keyboardConstraint.constant = 0
        
        UIView.animate(withDuration: 0.5, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
        self.kbHeight = 0.0
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageTableCell
        
        let message: ChatMessage = self.messages.object(at: indexPath.item) as! ChatMessage
        
        cell.loadCell(message)
        
        cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        
        switch message.type{
        case messageType.message.rawValue:
            cell.username.text = message.username
            cell.username.textColor = getMessageColour(uuid: message.uuid)
            cell.message.text = message.content
            cell.message.textColor = UIColor.black
            let path = getExclusionPath(uuid: message.uuid, cell: cell)
            cell.message.textContainer.exclusionPaths = [path]
            cell.message.textAlignment = .left
            
        case messageType.connection.rawValue:
            cell.username.text = ""
            cell.message.text = "\(message.username) has joined chat"
            cell.message.textColor = UIColor.lightGray
            cell.message.textAlignment = .center
            
        case messageType.disconnection.rawValue:
            cell.username.text = ""
            cell.message.text = "\(message.username) has left chat"
            cell.message.textColor = UIColor.lightGray
            cell.message.textAlignment = .center
            
        default:
            cell.username.text = message.username
            cell.message.text = message.content
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func moveToBottom() {

        if messages.count > 0  {
            
            let indexPath = IndexPath(row: messages.count - 1, section: 0)
            
            messageTableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
        }
    }
    
    func getExclusionPath(uuid: String, cell: MessageTableCell)->UIBezierPath{
        if let sPath = self.rectMap[uuid] {
            return sPath
        }else{
            let rect: CGRect = CGRect(origin: cell.username.frame.origin, size: CGSize(width: cell.username.intrinsicContentSize.width + messagePadding, height: cell.username.frame.height - subUsernamePadding))
            let path = UIBezierPath(rect: rect)
            rectMap[uuid] = path
            return path
        }
    }

    
    func addRowToTable(){
        self.messageTableView.beginUpdates()
        let indexPath:IndexPath = IndexPath(row:(self.messages.count - 1), section:0)
        self.messageTableView.insertRows(at: [indexPath], with: UITableViewRowAnimation.bottom)
        self.messageTableView.endUpdates()
        self.messageTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        
        
    }
    
    func deviceConnected(){}
    func deviceLost(){}
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

class MessageTableCell: UITableViewCell {
    
    
    @IBOutlet weak var message: UITextView!
    @IBOutlet weak var username: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func loadCell(_ data: ChatMessage) {
        username.text = data.username
        message.text = data.content
    }
    
}
