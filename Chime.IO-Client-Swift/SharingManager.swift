//
//  SharingManager.swift
//  Chime.IO-Client-Swift
//
//  Created by JmeHsieh on 4/28/16.
//  Copyright © 2016 JmeHsieh. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class SharingManager {
    
    static let defaultManager = SharingManager()
    var currentUserInfo: (String, User)?
    var chioStatusOA: Observable<ChIOStatus>!
    
    
    // MARK: - Constructors
    init() {
        chioStatusOA = NSNotificationCenter.defaultCenter()
            .rx_notification(ChIONotification.StatusDidChange.rawValue)
            .map { n in
                if let u = n.userInfo, s = u[ChIONotificationKey.Status.rawValue] as? String {
                    switch s {
                    case ChIOStatus.NotConnected.rawValue:
                        return .NotConnected
                    case ChIOStatus.Closed.rawValue:
                        return .Closed
                    case ChIOStatus.Connecting.rawValue:
                        return .Connecting
                    case ChIOStatus.Connected.rawValue:
                        return .Connected
                    default:
                        return .Closed
                    }
                } else { return ChIOStatus.Closed }
            }
    }
}
