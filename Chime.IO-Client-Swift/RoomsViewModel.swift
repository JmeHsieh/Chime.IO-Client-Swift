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
    private var refreshedRoomsOA: Observable<[Room]>!
    var roomsOA: Observable<[Room]>!
    
    // MARK: - Constructors
    init(_ refreshD: Driver<Void>, incomingNewRoomOA: Observable<Room?>) {
        isloadingD = isloadingV.asDriver()
        
        refreshedRoomsOA = Observable.create { [unowned self] o in
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
        
        roomsOA = Observable.combineLatest(refreshedRoomsOA, incomingNewRoomOA) { rooms, room in
            var rms = rooms
            if let rm = room {
                let foundIndex = rms.indexOf { return $0.id == rm.id }
                if foundIndex == nil {
                    rms.append(rm)
                }
            }
            rms.sortInPlace {
                return $1.createdAt!.compare($0.createdAt!) == .OrderedAscending
            }
            return rms
        }.shareReplayLatestWhileConnected()
    }
    
    // MARK: - Instance Methods
    func reload() {
        reloadP.onNext()
    }
}