//
//  RoomsViewModel.swift
//  Chime.IO-Client-Swift
//
//  Created by JmeHsieh on 4/27/16.
//  Copyright © 2016 JmeHsieh. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class RoomsViewModel {
    
    private let isloadingV = Variable<Bool>(false)
    lazy var disposeBag = DisposeBag()
    
    var isloadingD: Driver<Bool>
    var roomsOA: Observable<[Room]>!
    
    init(_ refreshD: Driver<Void>) {
        isloadingD = isloadingV.asDriver()
        roomsOA = Observable.create { [unowned self] o in
            return refreshD.withLatestFrom(self.isloadingD)
                .filter { !$0 }
                .driveNext { l in
                    self.isloadingV.value = true
                    ChimeIOAPI.sharedInstance.getMyRooms().then { rms -> Void in
                        self.isloadingV.value = false
                        o.onNext(rms)
                    }
            }
        }.shareReplayLatestWhileConnected()
    }
}