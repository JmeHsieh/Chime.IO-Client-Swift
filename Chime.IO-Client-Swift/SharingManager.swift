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

typealias SignedUserInfo = (String, User)
class SharingManager {
    
    static let defaultManager = SharingManager()
    private let disposeBag = DisposeBag()
    var chioStatusOA: Observable<ChIOStatus>!
    var currentUserInfo: SignedUserInfo?
    
    
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
        
        // will-logout handler
        NSNotificationCenter.defaultCenter()
            .rx_notification(AppNotification.WillLogout.rawValue)
            .asObservable()
            .subscribeNext { _ in self.currentUserInfo = nil }
            .addDisposableTo(disposeBag)
    }
}
