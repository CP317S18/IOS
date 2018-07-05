//
//  ViewController.swift
//  shout
//
//  Created by Greg Murray on 2018-07-05.
//  Copyright © 2018 wlu. All rights reserved.
//

import UIKit

class ViewController: UIViewController, MessageRecievedDelegate {
    
    var client: BluetoothClient
    
    required init?(coder aDecoder: NSCoder) {
        client = BluetoothClient(coder: aDecoder)
        super.init(coder: aDecoder)
        
    }
    
    func onMessageReceived(message: ChatMessage) {
        print(message.content)
    }
    

    override open func viewDidLoad() {
        super.viewDidLoad()
        print("View Did Load")
        client.start()
        client.register(messageDelegate: self)
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}
