//
//  ChatViewController.swift
//  Chime.IO-Client-Swift
//
//  Created by JmeHsieh on 4/28/16.
//  Copyright © 2016 JmeHsieh. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import SnapKit
import UIKit

class ChatViewController: UIViewController {
    
    
    var roomID: String!
    let CellIdentifier = "CellIdentifier"
    var tableView: UITableView!
    var inputField: UITextField!
    var inputFieldBottomConstraint: Constraint?
    
    private let disposeBag = DisposeBag()
    var viewModel: ChatViewModel!

    // MARK: - Constructors
    init(roomID: String) {
        self.roomID = roomID
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Chat"
        
        // setup views
        tableView = UITableView(frame: view.bounds, style: .Plain)
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier)
        tableView.allowsSelection = false
        tableView.rowHeight = 65.0
        tableView.separatorStyle = .None
        
        inputField = UITextField()
        inputField.returnKeyType = .Send
        inputField.leftViewMode = .Always
        inputField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        inputField.font = UIFont(name: "Helvetica", size: 14.0)
        inputField.textColor = UIColor.darkGrayColor()
        inputField.backgroundColor = UIColor.whiteColor()
        inputField.borderStyle = .None
        inputField.layer.borderWidth = 0.5
        inputField.layer.borderColor = UIColor.lightGrayColor().CGColor
        
        view.addSubview(tableView)
        view.addSubview(inputField)
        
        tableView.snp_makeConstraints {
            $0.top.equalTo(view)
            $0.bottom.equalTo(inputField.snp_top)
            $0.centerX.equalTo(view)
            $0.width.equalTo(view)
        }
        
        inputField.snp_makeConstraints { [unowned self] in
            $0.centerX.equalTo(self.view)
            self.inputFieldBottomConstraint = $0.bottom.equalTo(self.view).constraint
            $0.width.equalTo(self.view)
            $0.height.equalTo(50.0)
        }
        
        // keyboard notification handler
        NSNotificationCenter.defaultCenter()
            .rx_notification(UIKeyboardWillShowNotification)
            .observeOn(MainScheduler.instance)
            .subscribeNext {
                if let  u = $0.userInfo,
                    f = u[UIKeyboardFrameEndUserInfoKey] as? NSValue,
                    d = u[UIKeyboardAnimationDurationUserInfoKey]?.doubleValue,
                    c = u[UIKeyboardAnimationCurveUserInfoKey]?.unsignedLongValue {
                    let kbHeight = f.CGRectValue().size.height
                    let duration = NSTimeInterval(d)
                    let opts = UIViewAnimationOptions(rawValue: c)
                    UIView.animateWithDuration(
                        duration,
                        delay: 0,
                        options: opts,
                        animations: {
                            self.inputFieldBottomConstraint?.updateOffset(-kbHeight)
                            self.view.layoutIfNeeded()
                        },
                        completion: { _ in self.adjustTableViewOffset(true) })
                }
        }.addDisposableTo(disposeBag)
        
        NSNotificationCenter.defaultCenter()
            .rx_notification(UIKeyboardWillHideNotification)
            .observeOn(MainScheduler.instance)
            .subscribeNext {
            if let  u = $0.userInfo,
                d = u[UIKeyboardAnimationDurationUserInfoKey]?.doubleValue,
                c = u[UIKeyboardAnimationCurveUserInfoKey]?.unsignedLongValue {
                let duration = NSTimeInterval(d)
                let opts = UIViewAnimationOptions(rawValue: c)
                UIView.animateWithDuration(
                    duration,
                    delay: 0,
                    options: opts,
                    animations: {
                        self.inputFieldBottomConstraint?.updateOffset(0)
                        self.view.layoutIfNeeded()
                    },
                    completion: nil)
                }
        }.addDisposableTo(disposeBag)
        
        // rx view model
        viewModel = ChatViewModel(roomID: roomID, inputField: inputField)
        
        viewModel.messagesD
            .asObservable()
            .bindTo(tableView.rx_itemsWithCellIdentifier(CellIdentifier, cellType: UITableViewCell.self)) {
            (row, message, cell) in
            
            if let currentUser = SharingManager.defaultManager.currentUserInfo?.1 where
                message.sender?.id == currentUser.id {
                cell.textLabel?.textAlignment = .Right
                cell.textLabel?.text = message.text
            } else {
                cell.textLabel?.textAlignment = .Left
                cell.textLabel?.text = "\(message.sender?.username ?? ""):  \(message.text)"
            }
        }.addDisposableTo(viewModel.disposeBag)
        
        viewModel.messagesD
            .driveNext { [unowned self] _ in self.adjustTableViewOffset(true) }
            .addDisposableTo(viewModel.disposeBag)
        
        viewModel.reloadMessages()
    }
    
    // MARK: - Private Methods
    private func adjustTableViewOffset(animated: Bool) {
        let ctHeight = self.tableView.contentSize.height
        let vsHeight = self.tableView.frame.size.height - self.tableView.contentInset.top - self.tableView.contentInset.bottom
        let offset = CGPointMake(self.tableView.contentOffset.x, max(ctHeight-vsHeight, 0) - self.tableView.contentInset.top)
        self.tableView.setContentOffset(offset, animated: animated)
    }
}
