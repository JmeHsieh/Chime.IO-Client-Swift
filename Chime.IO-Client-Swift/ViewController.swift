//
//  ViewController.swift
//  Chime.IO-Client-Swift
//
//  Created by JmeHsieh on 4/18/16.
//  Copyright © 2016 JmeHsieh. All rights reserved.
//

import UIKit
import PromiseKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        return
        ChimeIOAPI.sharedInstance.connect().then {
            return ChimeIOAPI.sharedInstance.login("jme_1@email.com", "00000000")
        }.then { (jwt, user) -> Promise<[Room]> in
            print("jwt: \(jwt)")
            print("user: \(user.username)")
            return ChimeIOAPI.sharedInstance.getMyRooms()
        }.then { rooms -> Promise<Room> in
            print(rooms)
            return ChimeIOAPI.sharedInstance.getRoom(rooms[0].id)
        }.then { room -> Promise<Message> in
            print(room)
            return ChimeIOAPI.sharedInstance.postMessage("today is a good day", inRoomID: room.id)
        }.then{ message in
            print(message)
        }.error { error in
            print(error)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

