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
    
    var client: BluetoothClient
    
    
    //User Defaults to persist Username
    let userDefaults = UserDefaults.standard
    var username: String?

    // Initialize Bluetooth Client
    required init?(coder aDecoder: NSCoder) {
        client = BluetoothClient(coder: aDecoder)
        super.init(coder: aDecoder)
    }
    
    // Outlets attached to StoryBoard
    @IBOutlet var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageField: UITextField!
    @IBOutlet weak var messageTableView: UITableView!
    
    @IBOutlet weak var navBarItem: UINavigationItem!
    //Array Containing the Messages
    var messages: NSMutableArray = []
    

    //When the "Send" button on they keyboard is pressed
    @IBAction func messagePrimaryActionTriggered(_ sender: Any) {
        if self.messageField.text!.isEmpty {
            return
        }
        self.sendMessage()
    }
    
    //Sends Message to Chat
    private func sendMessage() {
        let message: ChatMessage = ChatMessage()
        message.username = self.username!
        message.content = self.messageField.text!
        message.type = messageType.message.rawValue
        
        client.sendMessage(message)
        
        
        self.messageField.text = ""
        self.messages.add(message)
        
        self.addRowToTable()
    }
    //Handles Keyboard appearing
    @objc func keyboardWillShow(notification: NSNotification) {
        
        //Gets Keyboard size and adjusts view frame
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0{
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    //Handles Keyboard Dissapearing
    @objc func keyboardWillHide(notification: NSNotification) {
        
        //Gets Keyboard size and adjusts view frame
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y += keyboardSize.height
            }
        }
    }

    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Initial Bluetooth Client Setup
        client.start()
        client.register(messageDelegate: self)
        
        //Fetches username from userdefaults
        self.username = userDefaults.object(forKey: "username") as? String
        
        //TableView Init
        messageTableView.delegate = self
        
        messageTableView.dataSource = self
        
        messageTableView.rowHeight = UITableViewAutomaticDimension
        
        messageTableView.estimatedRowHeight = 300
        
        //Adds Observer for when Keyboard is shown and when keyboard will hide
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        //Recognizes tap on messages and closes keyboard
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        //Periodically scroll to bottom?
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
            
            self.moveToBottom()
            
        }
        
        self.messageTableView.tableFooterView = UIView()
        
        self.messageField.delegate = self
        
    }

    
    @objc func dismissKeyboard() {
        
        view.endEditing(true)
    }
    
    func addRowToTable(){
        self.messageTableView.beginUpdates()
        let indexPath:IndexPath = IndexPath(row:(self.messages.count - 1), section:0)
        self.messageTableView.insertRows(at: [indexPath], with: UITableViewRowAnimation.bottom)
        self.messageTableView.endUpdates()
        self.messageTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        
    }
    
    // Table View Functions
    
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
        
        userLabel.text = message.username
        messageLabel.text = message.content
        return cell
    }
    
    func moveToBottom() {

        if messages.count > 0  {
            
            let indexPath = IndexPath(row: messages.count - 1, section: 0)
            
            messageTableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
        }
    }
    
    
    func onMessageReceived(message: ChatMessage) {
        print("message recieived")
        print(message.content)
        self.messages.add(message)
        self.addRowToTable()
    }

}








