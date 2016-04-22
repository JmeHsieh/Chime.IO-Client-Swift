//
//  LoginViewController.swift
//  Chime.IO-Client-Swift
//
//  Created by JmeHsieh on 4/18/16.
//  Copyright © 2016 JmeHsieh. All rights reserved.
//

import UIKit
import PromiseKit
import RxSwift
import RxCocoa
import SnapKit

class LoginViewController: UIViewController {
    
    // MARK: -  Properties
    
    let disposeBag = DisposeBag()
    var emailTextField: UITextField?
    var passwordTextField: UITextField?
    
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.whiteColor()
        
        emailTextField = UITextField()
        emailTextField?.borderStyle = .RoundedRect
        emailTextField?.textColor = UIColor.blackColor()
        emailTextField?.placeholder = "email"
        emailTextField?.autocapitalizationType = .None
        emailTextField?.autocorrectionType = .No
        emailTextField?.keyboardType = .EmailAddress
        emailTextField?.returnKeyType = .Next
        
        passwordTextField = UITextField()
        passwordTextField?.borderStyle = .RoundedRect
        passwordTextField?.textColor = UIColor.blackColor()
        passwordTextField?.placeholder = "password"
        passwordTextField?.secureTextEntry = true
        passwordTextField?.returnKeyType = .Send
        
        if let emailTextField = emailTextField, passwordTextField = passwordTextField {
            
            self.view.addSubview(emailTextField)
            self.view.addSubview(passwordTextField)
            
            emailTextField.snp_makeConstraints { make in
                make.top.equalTo(self.view).offset(160)
                make.centerX.equalTo(self.view)
                make.width.equalTo(self.view).inset(40)
                make.height.equalTo(50)
            }
            passwordTextField.snp_makeConstraints { make in
                make.top.equalTo(emailTextField.snp_bottom).offset(20)
                make.size.equalTo(emailTextField)
                make.centerX.equalTo(emailTextField)
            }
        }
        
        emailTextField?.rx_controlEvent(.EditingDidEndOnExit).takeUntil(self.rx_deallocated).subscribe{
            [weak self] event in
            guard let strongSelf = self else { return }
            strongSelf.passwordTextField?.becomeFirstResponder()
        }.addDisposableTo(self.disposeBag)
        
        passwordTextField?.rx_controlEvent(.EditingDidEndOnExit).takeUntil(self.rx_deallocated).subscribe{
            [weak self] event in
            guard let strongSelf = self else { return }
            strongSelf.passwordTextField?.resignFirstResponder()
            print("sending!!!")
        }.addDisposableTo(self.disposeBag)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}

