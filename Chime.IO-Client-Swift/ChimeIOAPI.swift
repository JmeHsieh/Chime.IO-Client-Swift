//
//  ChimeIOAPI.swift
//  Chime.IO-Client-Swift
//
//  Created by JmeHsieh on 4/18/16.
//  Copyright © 2016 JmeHsieh. All rights reserved.
//

import Foundation
import ObjectMapper
import PromiseKit
import SocketIOClientSwift
import SwiftyJSON

enum SocketEvent: String {
    case Connect = "connect"
    case Disconnect = "disconnect"
    case Reconnect = "reconnect"
    case ReconnectAttempt = "reconnectAttempt"
    case Error = "error"
    case Authenticate = "authenticate"
    case Authenticated = "authenticated"
    case Unauthorized = "unauthorized"
}

enum ChimeIOAPIError: ErrorType {
    case GuardError(String)
    case JSONError(String)
}


class ChimeIOAPI {
    
    // MARK: - Singleton
    static let sharedInstance: ChimeIOAPI = {
        let instance = ChimeIOAPI(apiKey: "6c99cc19b2519e313157bd5b83256710bf413c0e",
                                  clientKey: "bd099f8193e5d2e2396b3d3dc6b59ed7d044a1b1",
                                  url: NSURL(string: "http://localhost:3030")!)
        instance.baseParams = ["apiKey": instance.apiKey, "clientKey": instance.clientKey]
        instance.registerEvents()
        return instance
    }()
    
    
    // MARK: - Properties
    private let userMapper = Mapper<User>()
    private let roomMapper = Mapper<Room>()
    private let messageMapper = Mapper<Message>()
    var socket: SocketIOClient!
    var apiKey: String!
    var clientKey: String!
    var baseParams: [String: String]!
    
    
    // MARK: - Constructors
    init(apiKey: String, clientKey: String, url: NSURL) {
        self.apiKey = apiKey
        self.clientKey = clientKey
        self.socket = SocketIOClient(socketURL: url,
                                     options: [.Log(false), .ForceWebsockets(true)])
        self.registerEvents()
    }
    
    
    // MARK: - Private Instance Methods
    private func registerEvents() {
        
        socket.onAny { event in
            print(event)
        }
        socket.on(SocketEvent.Connect.rawValue) { result, ack in
            print("default event handler: connect")
        }
        socket.on(SocketEvent.Disconnect.rawValue) { result, ack in
            print("default event handler: disconnect")
        }
        socket.on(SocketEvent.Reconnect.rawValue) { result, ack in
            print("default event handler: reconnect")
        }
        socket.on(SocketEvent.Reconnect.rawValue) { result, ack in
            print("socket event handler: reconnectAttempt")
        }
        socket.on(SocketEvent.Error.rawValue) { result, ack in
            print("socket event handler: error")
        }
        
        socket.on(SocketEvent.Authenticated.rawValue) { result, ack in
            print("authenticated")
        }
        socket.on(SocketEvent.Unauthorized.rawValue) { result, ack in
            print("unauthenticated")
        }
    }
    
    
    // MARK: - Public Instance Methods
    func connect() -> Promise<()> {
        return Promise { fulfill, reject in
            socket.once(SocketEvent.Connect.rawValue) { result, ack in
                fulfill()
            }
            socket.connect()
        }
    }
    
    
    // MARK: - User API
    private func _signup(username: String, _ email: String, _ password: String) -> Promise<User> {
        return Promise { fulfill, reject in
            guard username.characters.count > 0 else {
                throw ChimeIOAPIError.GuardError("username should contains at least 6 characters.")
            }
            guard email.containsString("@") else {
                throw ChimeIOAPIError.GuardError("email should contains at least a @ character.")
            }
            guard password.characters.count >= 8 else {
                throw ChimeIOAPIError.GuardError("password should be at least 8 characters long.")
            }
            
            let data = ["username": username, "email": email, "password": password]
            socket.emitWithAck("users::create", data, baseParams)(timeoutAfter: 0) { result in
                let json = JSON(result)
                if let user = self.userMapper.map(json[1].rawValue) {
                    fulfill(user)
                } else {
                    reject(ChimeIOAPIError.JSONError("ObjectMapper failed for result: \(result)"))
                }
            }
        }
    }
    
    func signup(username: String, _ email: String, _ password: String) -> Promise<(String, User)> {
        return self._signup(username, email, password).then { user in
            return self.login(username, password)
        }
    }
    
    func login(email: String, _ password: String) -> Promise<(String, User)> {
        return Promise { fulfill, reject in
            socket.once(SocketEvent.Authenticated.rawValue) { result, ack in
                let json = JSON(result)
                if let user = self.userMapper.map(json[0]["data"].rawValue) {
                    let jwt = json[0]["token"].stringValue
                    fulfill((jwt, user))
                } else {
                    reject(ChimeIOAPIError.JSONError("ObjectMapper failed for result: \(result)"))
                }
            }
            
            let params = ["type": "local", "email": email, "password": password]
            socket.emit(SocketEvent.Authenticate.rawValue, params)
        }
    }
    
    func login(jwt: String) -> Promise<(String, User)> {
        return Promise { fulfill, reject in
            socket.once(SocketEvent.Authenticated.rawValue) { result, ack in
                let json = JSON(result)
                if let user = self.userMapper.map(json[0]["data"].rawValue) {
                    let jwt = json[0]["token"].stringValue
                    fulfill((jwt, user))
                } else {
                    reject(ChimeIOAPIError.JSONError("ObjectMapper failed for result: \(result)"))
                }
            }
            
            let params = ["token": jwt]
            socket.emit(SocketEvent.Authenticate.rawValue, params)
        }
    }
    
    
    // MARK: - Room API
    func createRoom() -> Promise<Room> {
        return Promise { fulfill, reject in
            socket.emitWithAck("rooms::create", [:], baseParams)(timeoutAfter: 0) { result in
                let json = JSON(result)
                if let room = self.roomMapper.map(json[1].rawValue) {
                    fulfill(room)
                } else {
                    reject(ChimeIOAPIError.JSONError("ObjectMapper failed for result: \(result)"))
                }
            }
        }
    }
    
    func getMyRooms() -> Promise<[Room]> {
        return Promise { fulfill, reject in
            socket.emitWithAck("rooms::find", baseParams)(timeoutAfter: 0) { result in
                let json = JSON(result)
                if let rooms = self.roomMapper.mapArray(json[1]["data"].rawValue) {
                    fulfill(rooms)
                } else {
                    reject(ChimeIOAPIError.JSONError("ObjectMapper failed for result: \(result)"))
                }
            }
        }
    }
    
    func getRoom(id: String) -> Promise<Room> {
        return Promise { fulfill, reject in
            socket.emitWithAck("rooms::get", id, baseParams)(timeoutAfter: 0) { result in
                let json = JSON(result)
                if let room = self.roomMapper.map(json[1].rawValue) {
                    fulfill(room)
                } else {
                    reject(ChimeIOAPIError.JSONError("ObjectMapper failed for result: \(result)"))
                }
            }
        }
    }
    
    func joinRoom(id: String) -> Promise<Room> {
        return Promise { fulfill, reject in
            var params = baseParams
            params["action"] = "join"
            socket.emitWithAck("rooms::patch", id, [:], params)(timeoutAfter: 0) { result in
                let json = JSON(result)
                if let room = self.roomMapper.map(json[1].rawValue) {
                    fulfill(room)
                } else {
                    reject(ChimeIOAPIError.JSONError("ObjectMapper failed for result: \(result)"))
                }
            }
        }
    }
    
    func archiveRoom(id: String) -> Promise<Room> {
        return Promise { fulfill, reject in
            var params = baseParams
            params["action"] = "archive"
            socket.emitWithAck("rooms::patch", id, [:], params)(timeoutAfter: 0) { result in
                let json = JSON(result)
                if let room = self.roomMapper.map(json[1].rawValue) {
                    fulfill(room)
                } else {
                    reject(ChimeIOAPIError.JSONError("ObjectMapper failed for result: \(result)"))
                }
            }
        }
    }
    
    
    // MARK: - Message API
    func postMessage(text: String, inRoomID: String) -> Promise<Message> {
        return Promise { fulfill, reject in
            let data = ["text": text]
            var params = baseParams
            params["room"] = inRoomID
            socket.emitWithAck("messages::create", data, params)(timeoutAfter: 0) { result in
                let json = JSON(result)
                if let message = self.messageMapper.map(json[1].rawValue) {
                    fulfill(message)
                } else {
                    reject(ChimeIOAPIError.JSONError("ObjectMapper failed for result: \(result)"))
                }
            }
        }
    }
    
    func getMessages(inRoomID: String) -> Promise<[Message]> {
        return Promise { fulfill, reject in
            var params = baseParams
            params["room"] = inRoomID
            socket.emitWithAck("messages::find", params)(timeoutAfter: 0) { result in
                let json = JSON(result)
                if let messages = self.messageMapper.mapArray(json[1]["data"].rawValue) {
                    fulfill(messages)
                } else {
                    reject(ChimeIOAPIError.JSONError("ObjectMapper failed for result: \(result)"))
                }
            }
        }
    }
    
    func getMessage(id: String) -> Promise<Message> {
        return Promise { fulfill, reject in
            socket.emitWithAck("messages::get", id, baseParams)(timeoutAfter: 0) { result in
                let json = JSON(result)
                if let message = self.messageMapper.map(json[1].rawValue) {
                    fulfill(message)
                } else {
                    reject(ChimeIOAPIError.JSONError("ObjectMapper failed for result: \(result)"))
                }
            }
        }
    }
    
    func removeMessgae(id: String) -> Promise<Message> {
        return Promise { fulfill, reject in
            socket.emitWithAck("messages::remove", id, baseParams)(timeoutAfter: 0) { result in
                let json = JSON(result)
                if let message = self.messageMapper.map(json[1].rawValue) {
                    fulfill(message)
                } else {
                    reject(ChimeIOAPIError.JSONError("ObjectMapper failed for result: \(result)"))
                }
            }
        }
    }
    
    
}