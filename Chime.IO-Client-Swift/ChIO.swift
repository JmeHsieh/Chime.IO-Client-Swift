//
//  ChIO.swift
//  Chime.IO-Client-Swift
//
//  Created by JmeHsieh on 4/18/16.
//  Copyright © 2016 JmeHsieh. All rights reserved.
//

import Foundation
import Locksmith
import ObjectMapper
import PromiseKit
import SocketIOClientSwift
import SwiftyJSON



//---------------//
//  ChIOAccount  //
//---------------//

private let _Service = "__ChIO__"
private let _InternalAccount = "__ChIOInternalAccount__"
private enum ChIOAccountDataKey: String {
    case Email = "ChIOAccountEmailKey"
    case Password = "ChIOAccountPasswordKey"
    case Jwt = "ChIOAccountJwtKey"
}

struct ChIOAccount:
    ReadableSecureStorable,
    CreateableSecureStorable,
    DeleteableSecureStorable,
GenericPasswordSecureStorable {
    
    // Custome
    var email: String!
    var password: String!
    var jwt: String!
    
    // GenericPasswordSecureStorable
    let service = _Service
    var account: String { return email }
    
    // CreateableSecureStorable
    var data: [String: AnyObject] {
        return [ChIOAccountDataKey.Password.rawValue: password,
                ChIOAccountDataKey.Jwt.rawValue: jwt]
    }
    
    private init(email e: String) {
        email = e
    }
    
    init(email e: String, password p: String, jwt j: String) {
        email = e
        password = p
        jwt = j
    }
}



//------------//
//  ChIO API  //
//------------//

private enum SocketEvent: String {
    
    // SocketIO events
    case Connect = "connect"
    case Disconnect = "disconnect"
    case Reconnect = "reconnect"
    case ReconnectAttempt = "reconnectAttempt"
    case Error = "error"
    
    // Feathers events
    case Authenticate = "authenticate"
    case Authenticated = "authenticated"
    case Unauthorized = "unauthorized"
    case MessagesCreated = "messages created"
}

enum ChIOError: ErrorType {
    case GuardError(String)
    case JSONError(String)
    case OtherError(String)
}

enum ChIOStatus: String {
    case NotConnected = "NotConnected"
    case Closed = "Closed"
    case Connecting = "Connecting"
    case Connected = "Connected"
}

enum ChIONotification: String {
    case StatusDidChange = "StatusDidChangeNotification"
    case NewMessage = "NewMessageNotification"
}

enum ChIONotificationKey: String {
    case Status = "StatusKey"
    case NewMessage = "NewMessageKey"
}

class ChIO {
    
    // MARK: - Singleton
    static let sharedInstance: ChIO = {
        let xipURL = NSURL(string: "http://192.168.0.102.xip.io:3030")!
        let localURL = NSURL(string: "http://localhost:3030")!
        let instance = ChIO(apiKey: "6c99cc19b2519e313157bd5b83256710bf413c0e",
                            clientKey: "bd099f8193e5d2e2396b3d3dc6b59ed7d044a1b1",
                            url: localURL)
        return instance
    }()
    
    
    // MARK: - Properties
    
    // connection
    private var apiKey: String!
    private var clientKey: String!
    private var baseParams: [String: String]!
    private var socket: SocketIOClient!
    private(set) var status: ChIOStatus = .NotConnected {
        didSet {
            if status != oldValue {
                NSNotificationCenter.defaultCenter().postNotificationName(
                    ChIONotification.StatusDidChange.rawValue,
                    object: self,
                    userInfo: [ChIONotificationKey.Status.rawValue: status.rawValue])
            }
        }
    }
    
    // model
    private let userMapper = Mapper<User>()
    private let roomMapper = Mapper<Room>()
    private let messageMapper = Mapper<Message>()
    
    // account
    var account: ChIOAccount?
    
    
    // MARK: - Constructors
    init(apiKey: String, clientKey: String, url: NSURL) {
        self.apiKey = apiKey
        self.clientKey = clientKey
        self.baseParams = ["apiKey": apiKey, "clientKey": clientKey]
        self.socket = SocketIOClient(socketURL: url,
                                     options: [.Log(false), .ForceWebsockets(true)])
        
        self.registerEvents()
        
        // retrieve cached account if can
        let internalData = Locksmith.loadDataForUserAccount(_InternalAccount, inService: _Service)
        if let cachedEmail = internalData?[ChIOAccountDataKey.Email.rawValue] as? String {
            var a = ChIOAccount(email: cachedEmail)
            if let d = a.readFromSecureStore()?.data {
                a.password = d[ChIOAccountDataKey.Password.rawValue] as! String
                a.jwt = d[ChIOAccountDataKey.Jwt.rawValue] as! String
                account = a
            }
        }
    }
    
    
    // MARK: - Private Instance Methods
    private func registerEvents() {
        socket.onAny { event in
            if event.event == SocketEvent.MessagesCreated.rawValue,
                let message = event.items?.firstObject, m = self.messageMapper.map(message) {
                NSNotificationCenter.defaultCenter().postNotificationName(
                    ChIONotification.NewMessage.rawValue,
                    object: nil,
                    userInfo: [ChIONotificationKey.NewMessage.rawValue: m])
            }
        }
        socket.on(SocketEvent.Connect.rawValue) { [unowned self] result, ack in
            print(SocketEvent.Connect.rawValue)
            self.updateStatus(byEvent: SocketEvent.Connect)
        }
        socket.on(SocketEvent.Disconnect.rawValue) { [unowned self] result, ack in
            print(SocketEvent.Disconnect.rawValue)
            self.updateStatus(byEvent: SocketEvent.Disconnect)
        }
        socket.on(SocketEvent.Reconnect.rawValue) { [unowned self] result, ack in
            print(SocketEvent.Reconnect.rawValue)
            self.updateStatus(byEvent: SocketEvent.Reconnect)
        }
        socket.on(SocketEvent.ReconnectAttempt.rawValue) { [unowned self] result, ack in
            print(SocketEvent.ReconnectAttempt.rawValue)
            self.updateStatus(byEvent: SocketEvent.ReconnectAttempt)
        }
        socket.on(SocketEvent.Error.rawValue) { [unowned self] result, ack in
            print(SocketEvent.Error.rawValue)
            self.updateStatus(byEvent: SocketEvent.Error)
        }
        
        socket.on(SocketEvent.Authenticated.rawValue) { result, ack in
            print(SocketEvent.Authenticated.rawValue)
        }
        socket.on(SocketEvent.Unauthorized.rawValue) { result, ack in
            print(SocketEvent.Unauthorized.rawValue)
        }
    }
    
    private func updateStatus(byEvent event: SocketEvent) {
        var cStatus: ChIOStatus!
        switch event {
        case .Connect:
            cStatus = .Connected
        case .Reconnect:
            cStatus = .Connecting
        case .ReconnectAttempt:
            cStatus = .Connecting
        case .Disconnect:
            cStatus = .Closed
        case .Error:
            cStatus = .Closed
        default:
            cStatus = .NotConnected
        }
        status = cStatus
    }
    
    private func updateAccount(byEmail e: String, password p: String, jwt j: String) {
        
        // update account
        if var a = self.account {
            if a.email == e {
                a.password = p
                a.jwt = j
                do { try Locksmith.updateData(a.data, forUserAccount: a.account, inService: a.service) }
                catch { print(error) }
            } else {
                do { try a.deleteFromSecureStore() } catch { print(error) }
                do { try ChIOAccount(email: e, password: p, jwt: j).createInSecureStore() } catch { print(error) }
            }
        } else {
            do { try ChIOAccount(email: e, password: p, jwt: j).createInSecureStore() } catch { print(error) }
        }
        
        // cache email
        do { try Locksmith.updateData([ChIOAccountDataKey.Email.rawValue: e],
                                      forUserAccount: _InternalAccount,
                                      inService: _Service) }
        catch { print(error) }
    }
    
    private func updateAccount(byEmail e: String, jwt j: String) {
        if var a = self.account where a.email == e {
            a.jwt = j
            do { try Locksmith.updateData(a.data, forUserAccount: a.account, inService: a.service) }
            catch { print(error) }
        }
    }
    
    
    // MARK: - Public Instance Methods
    func connect() -> Promise<()> {
        return Promise { fulfill, reject in
            socket.once(SocketEvent.Connect.rawValue) { result, ack in
                fulfill()
            }
            status = .Connecting
            socket.connect()
        }
    }
    
    
    // MARK: - User API
    private func _signup(username: String, _ email: String, _ password: String) -> Promise<User> {
        return Promise { fulfill, reject in
            guard username.characters.count > 0 else {
                throw ChIOError.GuardError("username should contains at least 6 characters.")
            }
            guard email.containsString("@") else {
                throw ChIOError.GuardError("email should contains at least a @ character.")
            }
            guard password.characters.count >= 8 else {
                throw ChIOError.GuardError("password should be at least 8 characters long.")
            }
            
            let data = ["username": username, "email": email, "password": password]
            socket.emitWithAck("users::create", data, baseParams)(timeoutAfter: 0) { result in
                let json = JSON(result)
                if let user = self.userMapper.map(json[1].rawValue) {
                    fulfill(user)
                } else {
                    reject(ChIOError.JSONError("ObjectMapper failed for result: \(result)"))
                }
            }
        }
    }
    
    func signup(username: String, _ email: String, _ password: String) -> Promise<(String, User)> {
        return self._signup(username, email, password).then { user in
            return self.login(email, password)
        }
    }
    
    func login(email: String, _ password: String) -> Promise<(String, User)> {
        return Promise { fulfill, reject in
            socket.once(SocketEvent.Authenticated.rawValue) { [unowned self] result, ack in
                let json = JSON(result)
                if let user = self.userMapper.map(json[0]["data"].rawValue) {
                    let jwt = json[0]["token"].stringValue
                    self.updateAccount(byEmail: email, password: password, jwt: jwt)
                    fulfill((jwt, user))
                } else {
                    reject(ChIOError.JSONError("ObjectMapper failed for result: \(result)"))
                }
            }
            socket.once(SocketEvent.Unauthorized.rawValue) { result, ack in
                reject(ChIOError.OtherError(SocketEvent.Unauthorized.rawValue))
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
                    self.updateAccount(byEmail: user.email, jwt: jwt)
                    fulfill((jwt, user))
                } else {
                    reject(ChIOError.JSONError("ObjectMapper failed for result: \(result)"))
                }
            }
            socket.once(SocketEvent.Unauthorized.rawValue) { result, ack in
                reject(ChIOError.OtherError(SocketEvent.Unauthorized.rawValue))
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
                    reject(ChIOError.JSONError("ObjectMapper failed for result: \(result)"))
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
                    reject(ChIOError.JSONError("ObjectMapper failed for result: \(result)"))
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
                    reject(ChIOError.JSONError("ObjectMapper failed for result: \(result)"))
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
                    reject(ChIOError.JSONError("ObjectMapper failed for result: \(result)"))
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
                    reject(ChIOError.JSONError("ObjectMapper failed for result: \(result)"))
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
                    reject(ChIOError.JSONError("ObjectMapper failed for result: \(result)"))
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
                    reject(ChIOError.JSONError("ObjectMapper failed for result: \(result)"))
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
                    reject(ChIOError.JSONError("ObjectMapper failed for result: \(result)"))
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
                    reject(ChIOError.JSONError("ObjectMapper failed for result: \(result)"))
                }
            }
        }
    }
}