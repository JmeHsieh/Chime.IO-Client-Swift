//
//  LoginViewModel.swift
//  Chime.IO-Client-Swift
//
//  Created by JmeHsieh on 4/22/16.
//  Copyright © 2016 JmeHsieh. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class LoginViewModel {
    
    private let isloadingV = Variable<Bool>(false)
    lazy var disposeBag = DisposeBag()
    
    // ui
    var emailD: Driver<String>
    var passwordD: Driver<String>
    var sendButtonTapD: Driver<Void>
    var spinnerAnimatingO: AnyObserver<Bool>
    var sendButtonEnabledO: AnyObserver<Bool>
    
    // login result
    typealias LoginResult = (String, User)
    var loginOA: Observable<LoginResult?>!
    
    
    init(email: Driver<String>,
         password: Driver<String>,
         spinnerAnimating: AnyObserver<Bool>,
         sendButtonTap: Driver<Void>,
         sendButtonEnabled: AnyObserver<Bool>) {
        emailD = email
        passwordD = password
        spinnerAnimatingO = spinnerAnimating
        sendButtonTapD = sendButtonTap
        sendButtonEnabledO = sendButtonEnabled
        
        let isloadingD = isloadingV.asDriver().distinctUntilChanged()
        
        // spinner animation
        isloadingV.asObservable().bindTo(spinnerAnimatingO).addDisposableTo(disposeBag)
        
        // send button enabled state
        let eValid = emailD.map { $0.containsString("@") }.distinctUntilChanged()
        let pValid = passwordD.map { $0.characters.count >= 8 }.distinctUntilChanged()
        Driver.combineLatest(eValid, pValid, isloadingD) { $0 && $1 && !$2 }
            .asObservable()
            .distinctUntilChanged()
            .bindTo(sendButtonEnabledO)
            .addDisposableTo(disposeBag)
        
        // login result as observable
        loginOA = Observable.create { [weak self] o in
            guard let `self` = self else { return NopDisposable.instance }
            return self.sendButtonTapD
                .withLatestFrom(isloadingD)
                .filter { !$0 }
                .withLatestFrom(Driver.combineLatest(self.emailD, self.passwordD) { ($0, $1) })
                .driveNext {
                    self.isloadingV.value = true
                    ChimeIOAPI.sharedInstance.login($0, $1).then { (jwt, user) -> Void in
                        self.isloadingV.value = false
                        o.onNext((jwt, user))
                        o.onCompleted()
                    }.error { e in
                        self.isloadingV.value = false
                        o.onNext(nil)
                    }
            }
        }.shareReplayLatestWhileConnected()
    }
}