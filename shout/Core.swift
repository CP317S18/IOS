//
//  BluetoothClient.swift
//  shout
//
//  Created by Greg Murray on 2018-07-05.
//  Copyright © 2018 wlu. All rights reserved.
//

import BFTransmitter



open class BluetoothClient: NSObject, BFTransmitterDelegate {
    
    fileprivate var transmitter: BFTransmitter
    fileprivate var messsageReceiveDelegates: Array<MessageRecievedDelegate>
    fileprivate var connectionDelegates: Array<ConnectionDelegate>
    fileprivate var connectedDevices: Int
    fileprivate var failedMessages: Array<ChatMessage>
    fileprivate var connectedDeviceList: Array<String>
    
    fileprivate var usernameKey = "username"
    fileprivate var contentKey = "content"
    fileprivate var typeKey = "type"
    fileprivate var uuid = ""
    
    public func getConnectedCount() -> Int{
        return self.connectedDevices
    }
    
    public func getUUID() -> String{
        return self.uuid
    }
    
    fileprivate static let instance = BluetoothClient()
    
    public static func getInstance() -> BluetoothClient{
        return self.instance
    }
        
    public required override init(){
        print("Initalizing Bluetooth Client")
        self.transmitter = BFTransmitter(apiKey: "ec174e51-a4ab-4e01-9908-fe53b2833622")
        self.messsageReceiveDelegates = Array()
        self.connectionDelegates = Array()
        self.connectedDevices = 0
        self.failedMessages = Array()
        self.connectedDeviceList = Array()
        super.init()
        self.transmitter.delegate = self
        self.transmitter.isBackgroundModeEnabled = true
        self.uuid = self.transmitter.currentUser!
        
        BFTransmitter.setLogLevel(BFLogLevel.trace)
        
    }
    
    public func start(){
        print("Transmitter Starting from init")
        self.transmitter.start();
    }
    
    public func transmitter(_ transmitter: BFTransmitter, didSendDirectPacket packetID: String) {
        
    }
    
    public func transmitter(_ transmitter: BFTransmitter, didFailForPacket packetID: String, error: Error?) {
        
    }
    
    public func transmitter(_ transmitter: BFTransmitter, didReceive dictionary: [String : Any]?, with data: Data?, fromUser user: String, packetID: String, broadcast: Bool, mesh: Bool) {
        if(mesh){
            let message : ChatMessage = ChatMessage(dictionary: dictionary!, date:Date(), uuid: user)
            for i in 0 ... messsageReceiveDelegates.count - 1{
                messsageReceiveDelegates[i].onMessageReceived(message: message)
            }
        }
    }
    
    public func transmitter(_ transmitter: BFTransmitter, didDetectConnectionWithUser user: String) {
        self.connectedDevices += 1
        print("Gained \(user)")
        if !self.connectedDeviceList.contains(user) {
            self.connectedDeviceList.append(user)
        }else{
            print("Already in Dict")
        }
        for i in 0 ... connectionDelegates.count - 1{
            connectionDelegates[i].deviceConnected()
            connectionDelegates[i].numberOfDevicesConnectedChanged(count: self.connectedDevices)
        }
    }
    
    public func transmitter(_ transmitter: BFTransmitter, didDetectDisconnectionWithUser user: String) {
        self.connectedDevices -= 1
        print("Lost \(user)")
        if self.connectedDeviceList.contains(user){
            if let index = self.connectedDeviceList.index(of: user) {
                self.connectedDeviceList.remove(at: index)
            }
        }else{
            print("Was not in Dict upon disconnection")
        }
        for i in 0 ... connectionDelegates.count - 1{
            connectionDelegates[i].deviceConnected()
            connectionDelegates[i].numberOfDevicesConnectedChanged(count: self.connectedDevices)
        }
    }
    
    public func transmitter(_ transmitter: BFTransmitter, didFailAtStartWithError error: Error) {
        
    }
    
    public func transmitter(_ transmitter: BFTransmitter, shouldConnectSecurelyWithUser user: String) -> Bool {
        return false //if true establish connection with encryption capacities.
    }
    
    public func register(messageDelegate:MessageRecievedDelegate){
        print("Added Message Delegate")
        messsageReceiveDelegates.append(messageDelegate)
    }
    
    public func transmitter(_ transmitter: BFTransmitter, didOccur event: BFEvent, description: String)
    {
        print("Event reported: \(description)");
    }
    
    /*public func unRegister(messageDelegate:MessageRecievedDelegate){
        if let index = messsageReceiveDelegates.index(object:messageDelegate) {
            messsageReceiveDelegates.remove(at: index)
        }
    }*/
    
    public func register(connectionDelegate:ConnectionDelegate){
        print("Added Connection Delegate")
        connectionDelegates.append(connectionDelegate)
    }
    
    
    
   /* public func unRegister(connectionDelegate:ConnectionDelegate){
        if let index = connectionDelegates.index(where:{$0 == connectionDelegate}) {
            connectionDelegates.remove(at: index)
        }
    }*/
    
    open func sendMessage(_ message: ChatMessage){
        var dictionary: Dictionary<String, Any>
        var options: BFSendingOption
        
        options = [.meshTransmission]
        
        dictionary = [
            usernameKey: message.username,
            contentKey: message.content,
            typeKey: message.type
        ]
        print("sending direct message")
        for i in 0 ... connectedDeviceList.count - 1{
            do {
                try self.transmitter.send(dictionary, toUser: connectedDeviceList[i], options: options)
            }
            catch let err as NSError {
                print("Send Message to \(connectedDeviceList[i]) Error: \(err)")
            }
        }
        
    }
    
    
}

public protocol MessageRecievedDelegate{
    func onMessageReceived(message:ChatMessage)
}
public protocol ConnectionDelegate{
    func deviceConnected()
    func deviceLost()
    func numberOfDevicesConnectedChanged(count: Int)
}
