//
//  Room.swift
//  Chime.IO-Client-Swift
//
//  Created by JmeHsieh on 4/19/16.
//  Copyright © 2016 JmeHsieh. All rights reserved.
//

import Foundation
import ObjectMapper
import SwiftyJSON

class Room: Mappable {
    
    var id: String
    var members: [User]
    var archivedIDs: [String]
    var isPublic: Bool = false
    var createdAt: NSDate?
    var updatedAt: NSDate?
    
    init(id: String, members: [User], archivedIDs: [String], isPublic: Bool, createdAt: NSDate?, updatedAt: NSDate?) {
        self.id = id
        self.members = members
        self.archivedIDs = archivedIDs
        self.isPublic = isPublic
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    
    // MARK: - Mappable Protocol
    
    required init?(_ map: Map) {
        id = ""
        members = []
        archivedIDs = []
    }
    
    func mapping(map: Map) {
        id          <- map["_id"]
        members     <- map["users"]
        archivedIDs <- map["archivedBy"]
        isPublic    <- map["isPublic"]
        createdAt   <- (map["createdAt"], DateFormatterTransform(dateFormatter: Utility.dateFormatter))
        updatedAt   <- (map["updatedAt"], DateFormatterTransform(dateFormatter: Utility.dateFormatter))
    }
}