//
//  Message.swift
//  shout
//
//  Created by Greg Murray on 2018-07-04.
//  Copyright © 2018 wlu. All rights reserved.
//

import UIKit

open class ChatMessage: NSObject, NSCoding {
    var username: String
    var content: String
    var date: Date
    
    override required public init()
    {
        self.username = ""
        self.content = ""
        self.date = Date()
    }
    
    required public init(dictionary: Dictionary<String, Any>, date: Date) {
        self.username = dictionary["username"] as! String
        self.content = dictionary["content"] as! String
        self.date = date
    }
    
    required public init(coder decoder: NSCoder) {
        self.username =  decoder.decodeObject(forKey: "username") as! String
        self.content = decoder.decodeObject(forKey: "content") as! String
        self.date = decoder.decodeObject(forKey: "date") as! Date
        
    }
    
    open func encode(with encoder: NSCoder) {
        encoder.encode(self.username, forKey: "username")
        encoder.encode(self.content, forKey: "content")
        encoder.encode(self.date, forKey: "date")
    }
    
}
