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
    
    private let disposeBag = DisposeBag()
    private let isloadingV = Variable<Bool>(false)
    
    // ui
    var emailD: Driver<String>
    var passwordD: Driver<String>
    var sendD: Driver<String>
    var spinnerAnimatingO: AnyObserver<Bool>
    var sendButtonEnabledO: AnyObserver<Bool>
    
    // login result
    typealias Result = (String, User)
    var loginOA: Observable<Result?>!
    var signupOA: Observable<Result?>!
    
    
    init(email: Driver<String>,
         password: Driver<String>,
         spinnerAnimating: AnyObserver<Bool>,
         send: Driver<String>,
         sendButtonEnabled: AnyObserver<Bool>) {
        emailD = email
        passwordD = password
        spinnerAnimatingO = spinnerAnimating
        sendD = send
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
        loginOA = Observable.create { [unowned self] o in
            return self.sendD
                .filter { $0 == "Login" }
                .withLatestFrom(isloadingD)
                .filter { !$0 }
                .withLatestFrom(Driver.combineLatest(self.emailD, self.passwordD) { ($0, $1) })
                .driveNext {
                    self.isloadingV.value = true
                    ChIO.sharedInstance.login($0, $1).then { (jwt, user) -> Void in
                        self.isloadingV.value = false
                        o.onNext((jwt, user))
                        o.onCompleted()
                    }.error { e in
                        self.isloadingV.value = false
                        o.onNext(nil)
                    }
            }
        }.shareReplayLatestWhileConnected()
        
        // signup result as observable
        signupOA = Observable.create { [unowned self] o in
            return self.sendD
                .filter { $0 == "Signup" }
                .withLatestFrom(isloadingD)
                .filter { !$0 }
                .withLatestFrom(Driver.combineLatest(self.emailD, self.passwordD) {
                    ($0.componentsSeparatedByString("@").first ?? "your username", $0, $1)
                })
                .driveNext {
                    self.isloadingV.value = true
                    ChIO.sharedInstance.signup($0, $1, $2).then { (jwt, user) -> Void in
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