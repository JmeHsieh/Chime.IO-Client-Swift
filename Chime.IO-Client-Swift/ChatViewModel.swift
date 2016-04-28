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

class ChatViewModel {
    
    private let isloadingV = Variable<Bool>(false)
    lazy var disposeBag = DisposeBag()
    
    var isloadingD: Driver<Bool>
    var messagesOA: Observable<[Message]>!
    
    init(roomID: String) {
        isloadingD = isloadingV.asDriver()
        messagesOA = Observable.create { o in
            ChimeIOAPI.sharedInstance.getMessages(roomID).then { [unowned self] ms -> Void in
                self.isloadingV.value = false
                o.onNext(ms)
            }
            return NopDisposable.instance
        }.shareReplayLatestWhileConnected()
        
    }
}

