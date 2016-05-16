//
//  Message.swift
//  Chime.IO-Client-Swift
//
//  Created by JmeHsieh on 4/20/16.
//  Copyright © 2016 JmeHsieh. All rights reserved.
//

import Foundation
import ObjectMapper
import SwiftyJSON

enum MessageType: String {
    case Text = "text"
    case Image = "image"
    case Audio = "audio"
    case Video = "video"
    case Geo = "GEO"
    case Sticker = "sticker"
    case Other = "other"
}

class Message: Mappable {
    
    var id: String
    var text: String
    var sender: User?
    var roomID: String
    var messageType: MessageType = .Text
    var createdAt: NSDate?
    var updatedAt: NSDate?
    
    init(id: String, text t: String, sender s: User, roomID rmID: String, messageType msgType: MessageType, createdAt crAt: NSDate?, updatedAt upAt: NSDate?) {
        self.id = id
        self.text = t
        self.sender = s
        self.roomID = rmID
        self.messageType = msgType
        self.createdAt = crAt
        self.updatedAt = upAt
    }
    
    
    // MARK: - Mappable Protocol
    
    required init?(_ map: Map) {
        id = ""
        text = ""
        roomID = ""
    }
    
    func mapping(map: Map) {
        id          <- map["_id"]
        text        <- map["text"]
        sender      <- map["user"]
        roomID      <- map["room"]
        messageType <- map["messageType"]
        createdAt   <- (map["createdAt"], DateFormatterTransform(dateFormatter: Utility.dateFormatter))
        updatedAt   <- (map["updatedAt"], DateFormatterTransform(dateFormatter: Utility.dateFormatter))
    }
}