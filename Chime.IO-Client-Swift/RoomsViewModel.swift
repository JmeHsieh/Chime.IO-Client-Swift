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
    
    private let reloadP = PublishSubject<Void>()
    private let isloadingV = Variable<Bool>(false)
    var isloadingD: Driver<Bool>
    var roomsOA: Observable<[Room]>!
    
    // MARK: - Constructors
    init(_ refreshD: Driver<Void>) {
        isloadingD = isloadingV.asDriver()
        roomsOA = Observable.create { [unowned self] o in
            return [refreshD.asObservable(), self.reloadP.asObservable()]
                .toObservable()
                .merge()
                .withLatestFrom(self.isloadingD)
                .filter { !$0 }
                .subscribeOn(MainScheduler.instance)
                .subscribeNext { l in
                    self.isloadingV.value = true
                    ChIO.sharedInstance.getMyRooms().then { rms -> Void in
                        self.isloadingV.value = false
                        o.onNext(rms)
                    }
            }
        }.shareReplayLatestWhileConnected()
    }
    
    // MARK: - Instance Methods
    func reload() {
        reloadP.onNext()
    }
}