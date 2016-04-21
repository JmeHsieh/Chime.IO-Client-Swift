//
//  User.swift
//  Chime.IO-Client-Swift
//
//  Created by JmeHsieh on 4/19/16.
//  Copyright © 2016 JmeHsieh. All rights reserved.
//

import Foundation
import ObjectMapper
import SwiftyJSON

class User: Mappable {
    
    var id: String
    var username: String
    var email: String
    var createdAt: NSDate?
    var updatedAt: NSDate?
    
    init(id: String, username: String, email: String, createdAt: NSDate?, updatedAt: NSDate?) {
        self.id = id
        self.username = username
        self.email = email
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    
    // MARK: - Mappable Protocol
    
    required init?(_ map: Map) {
        id = ""
        username = ""
        email = ""
    }
    
    func mapping(map: Map) {
        id          <- map["_id"]
        username    <- map["username"]
        email       <- map["email"]
        createdAt   <- (map["createdAt"], DateFormatterTransform(dateFormatter: Utility.dateFormatter))
        updatedAt   <- (map["updatedAt"], DateFormatterTransform(dateFormatter: Utility.dateFormatter))
    }
}