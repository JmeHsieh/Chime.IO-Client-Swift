//
//  ChatViewModel.swift
//  Chime.IO-Client-Swift
//
//  Created by JmeHsieh on 4/28/16.
//  Copyright © 2016 JmeHsieh. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit

class ChatViewModel {
    
    var roomID: String!
    lazy var disposeBag = DisposeBag()
    
    var messagesD: Driver<[Message]>!
    private let messagesV = Variable<[Message]>([])
    
    var isreloadingD: Driver<Bool>
    private let isreloadingV = Variable<Bool>(false)
    
    var ispostingD: Driver<Bool>
    private let ispostingV = Variable<Bool>(false)
    
    
    init(roomID: String, inputField: UITextField) {
        messagesD = messagesV.asDriver()
        isreloadingD = isreloadingV.asDriver()
        ispostingD = ispostingV.asDriver()
        self.roomID = roomID
            
        let inputFieldTextD = inputField.rx_text.asDriver()
        let inputFieldReturnD = inputField.rx_controlEvent(.EditingDidEndOnExit).asDriver()
        
        // bind inputField's return key event to api-calling
        inputFieldReturnD.withLatestFrom(ispostingD)
            .filter { !$0 }
            .withLatestFrom(inputFieldTextD)
            .driveNext { [unowned self] in
                self.ispostingV.value = true
                ChIO.sharedInstance.postMessage($0, inRoomID: roomID).then { m  -> Void in
                    self.ispostingV.value = false
                    var ms = self.messagesV.value
                    let foundIndex = ms.indexOf { return $0.id == m.id }
                    if foundIndex == nil {
                        ms.append(m)
                        ms.sortInPlace {
                            return $1.createdAt!.compare($0.createdAt!) == .OrderedDescending
                        }
                    }
                    self.messagesV.value = ms
                    inputField.text = nil
                }.error { _ in
                    self.ispostingV.value = false
                }
        }.addDisposableTo(disposeBag)
        
        NSNotificationCenter.defaultCenter().rx_notification(ChIONotification.NewMessageNotification.rawValue).subscribeNext { n in
            if let userInfo = n.userInfo where userInfo["message"] != nil {
                var ms = self.messagesV.value
                ms.append(userInfo[ChIONotificationKey.NewMessageKey.rawValue] as! Message)
                ms.sortInPlace {
                    return $1.createdAt!.compare($0.createdAt!) == .OrderedDescending
                }
                self.messagesV.value = ms
            }
        }.addDisposableTo(disposeBag)
    }
    
    func reloadMessages() {
        self.isreloadingV.value = true
        ChIO.sharedInstance.getMessages(roomID).then { ms -> Void in
            self.isreloadingV.value = false
            self.messagesV.value = ms
        }.error { _ in
            self.isreloadingV.value = false
        }
    }
}

