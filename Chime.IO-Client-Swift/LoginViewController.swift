//
//  LoginViewController.swift
//  Chime.IO-Client-Swift
//
//  Created by JmeHsieh on 4/18/16.
//  Copyright © 2016 JmeHsieh. All rights reserved.
//

import UIKit
import PromiseKit
import RxCocoa
import RxSwift
import SnapKit

class LoginViewController: UIViewController {
    
    var emailTextField: UITextField!
    var passwordTextField: UITextField!
    var sendButton: UIButton!
    var spinner: UIActivityIndicatorView!
    
    var viewModel: LoginViewModel!
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.whiteColor()
        
        emailTextField = UITextField()
        emailTextField.borderStyle = .RoundedRect
        emailTextField.textColor = UIColor.blackColor()
        emailTextField.placeholder = "email"
        emailTextField.autocapitalizationType = .None
        emailTextField.autocorrectionType = .No
        emailTextField.keyboardType = .EmailAddress
        emailTextField.returnKeyType = .Next
        
        passwordTextField = UITextField()
        passwordTextField.borderStyle = .RoundedRect
        passwordTextField.textColor = UIColor.blackColor()
        passwordTextField.placeholder = "password"
        passwordTextField.secureTextEntry = true
        passwordTextField.returnKeyType = .Send
        
        spinner = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        spinner.hidesWhenStopped = true
        
        sendButton = UIButton(type: .System)
        sendButton.titleLabel?.font = UIFont(name: "Helvetica", size: 16.0)
        sendButton.setTitle("Send", forState: .Normal)
        sendButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
        sendButton.setTitleColor(UIColor(white: 0, alpha: 0.2), forState: .Disabled)
        
        view.addSubview(emailTextField)
        view.addSubview(passwordTextField)
        view.addSubview(spinner)
        view.addSubview(sendButton)
        
        // constraints
        emailTextField.snp_makeConstraints {
            $0.top.equalTo(view).offset(160)
            $0.centerX.equalTo(view)
            $0.width.equalTo(view).inset(40)
            $0.height.equalTo(50)
        }
        
        passwordTextField.snp_makeConstraints {
            $0.top.equalTo(emailTextField.snp_bottom).offset(20)
            $0.size.equalTo(emailTextField)
            $0.centerX.equalTo(emailTextField)
        }
        
        spinner.snp_makeConstraints {
            $0.top.equalTo(passwordTextField.snp_bottom).offset(20)
            $0.centerX.equalTo(view)
            $0.size.equalTo(CGSizeMake(20, 20))
        }
        
        sendButton.snp_makeConstraints {
            $0.top.equalTo(spinner.snp_bottom)
            $0.size.equalTo(passwordTextField)
            $0.centerX.equalTo(passwordTextField)
        }
        
        // rx
        viewModel = LoginViewModel(email: emailTextField.rx_text.asDriver(),
                                   password: passwordTextField.rx_text.asDriver(),
                                   spinnerAnimating: spinner.rx_animating,
                                   sendButtonTap: sendButton.rx_tap.asDriver(),
                                   sendButtonEnabled: sendButton.rx_enabled)
        
        viewModel.loginOA.subscribeNext {
            if let userinfo = $0 {
                print("login succeed")
                print("jwt \(userinfo.0)")
                print("user \(userinfo.1)")
                SharingManager.defaultManager.currentUserInfo = userinfo
            } else {
                print("login failed")
            }
        }.addDisposableTo(viewModel.disposeBag)
        
        viewModel.loginOA.subscribeCompleted {
            print("go to next page")
            dispatch_async(dispatch_get_main_queue()) {
                self.navigationController?.pushViewController(RoomsViewController(), animated: true)
            }
        }.addDisposableTo(viewModel.disposeBag)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

