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
    var chioStatusOA: Observable<String>!
    
    
    // MARK: - Constructors
    
    init() {
        chioStatusOA = NSNotificationCenter.defaultCenter()
            .rx_notification(ChIONotification.StatusDidChangeNotification.rawValue)
            .map { n in
                if let u = n.userInfo, s = u[ChIONotificationKey.StatusKey.rawValue] as? String {
                    return s
                } else { return "" }
            }
    }
}
