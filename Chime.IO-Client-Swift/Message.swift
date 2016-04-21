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
    var messageType: MessageType = .Text
    var createdAt: NSDate?
    var updatedAt: NSDate?
    
    init(id: String, text: String, messageType: MessageType, createdAt: NSDate?, updatedAt: NSDate?) {
        self.id = id
        self.text = text
        self.messageType = messageType
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    
    // MARK: - Mappable Protocol
    
    required init?(_ map: Map) {
        id = ""
        text = ""
    }
    
    func mapping(map: Map) {
        id          <- map["_id"]
        text        <- map["text"]
        messageType <- map["messageType"]
        createdAt   <- (map["createdAt"], DateFormatterTransform(dateFormatter: Utility.dateFormatter))
        updatedAt   <- (map["updatedAt"], DateFormatterTransform(dateFormatter: Utility.dateFormatter))
    }
}