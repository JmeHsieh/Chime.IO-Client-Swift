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
    
    // ui
    var emailTextField: UITextField!
    var passwordTextField: UITextField!
    var spinner: UIActivityIndicatorView!
    var sendButton: UIButton!
    var signAlert: UIAlertController!
    
    // rx
    private let disposeBag = DisposeBag()
    private let sendV = Variable<String>("")
    var sendD: Driver<String>?
    var viewModel: LoginViewModel!
    
    
    // MARK: - Constructros
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.whiteColor()
        
        // setup views
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
        passwordTextField.returnKeyType = .Done
        
        spinner = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        spinner.hidesWhenStopped = true
        
        sendButton = UIButton(type: .System)
        sendButton.titleLabel?.font = UIFont(name: "Helvetica", size: 16.0)
        sendButton.setTitle("Send", forState: .Normal)
        sendButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
        sendButton.setTitleColor(UIColor(white: 0, alpha: 0.2), forState: .Disabled)
        
        signAlert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        signAlert.addAction(UIAlertAction(title: "Login", style: .Default) { [unowned self] in self.sendV.value = $0.title! })
        signAlert.addAction(UIAlertAction(title: "Signup", style: .Default) { [unowned self] in self.sendV.value = $0.title! })
        signAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        view.addSubview(emailTextField)
        view.addSubview(passwordTextField)
        view.addSubview(spinner)
        view.addSubview(sendButton)
        
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
        emailTextField.rx_controlEvent(.EditingDidEndOnExit)
            .asDriver()
            .driveNext { [unowned self] _ in
                self.passwordTextField.becomeFirstResponder()
            }.addDisposableTo(disposeBag)
        
        passwordTextField.rx_controlEvent(.EditingDidEnd)
            .asDriver()
            .driveNext { [unowned self] _ in
            self.passwordTextField.resignFirstResponder()
        }.addDisposableTo(disposeBag)
        
        sendButton.rx_tap.asDriver().driveNext { [unowned self] _ in
            self.presentViewController(self.signAlert, animated: true, completion: nil)
        }.addDisposableTo(disposeBag)
        
        sendD = sendV.asDriver()
        
        viewModel = LoginViewModel(email: emailTextField.rx_text.asDriver(),
                                   password: passwordTextField.rx_text.asDriver(),
                                   spinnerAnimating: spinner.rx_animating,
                                   send: sendD!,
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
        }.addDisposableTo(disposeBag)
        
        viewModel.loginOA.subscribeCompleted {
            print("go to next page")
            dispatch_async(dispatch_get_main_queue()) {
                print(self.navigationController)
                self.navigationController?.pushViewController(RoomsViewController(), animated: true)
            }
        }.addDisposableTo(disposeBag)
        
        viewModel.signupOA.subscribeNext {
            if let userinfo = $0 {
                print("signup succeed")
                print("jwt \(userinfo.0)")
                print("user \(userinfo.1)")
                SharingManager.defaultManager.currentUserInfo = userinfo
            } else {
                print("signup failed")
            }
        }.addDisposableTo(disposeBag)
        
        viewModel.signupOA.subscribeCompleted {
            print("go to next page")
            dispatch_async(dispatch_get_main_queue()) {
                print(self.navigationController)
                self.navigationController?.pushViewController(RoomsViewController(), animated: true)
            }
        }.addDisposableTo(disposeBag)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

