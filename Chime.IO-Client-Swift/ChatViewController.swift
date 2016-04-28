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
import UIKit

class ChatViewController: UIViewController {
    
    var tableView: UITableView!
    var inputField: UITextField!
    let CellIdentifier = "CellIdentifier"
    var roomID: String!
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
        
        tableView = UITableView(frame: view.bounds, style: .Plain)
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier)
        tableView.allowsSelection = false
        tableView.rowHeight = 65.0
        tableView.separatorStyle = .None
        
        inputField = UITextField()
        inputField.returnKeyType = .Send
        inputField.font = UIFont(name: "Helvetica", size: 14.0)
        inputField.textColor = UIColor.darkGrayColor()
        inputField.borderStyle = .RoundedRect
        
        view.addSubview(tableView)
        view.addSubview(inputField)
        
        tableView.snp_makeConstraints {
            $0.top.equalTo(view)
            $0.bottom.equalTo(inputField.snp_top)
            $0.centerX.equalTo(view)
            $0.width.equalTo(view)
        }
        inputField.snp_makeConstraints {
            $0.centerX.equalTo(view)
            $0.bottom.equalTo(view)
            $0.width.equalTo(view)
            $0.height.equalTo(50.0)
        }
        
        viewModel = ChatViewModel(roomID: roomID, inputField: inputField)
        viewModel.messagesD
            .asObservable()
            .bindTo(tableView.rx_itemsWithCellIdentifier(CellIdentifier, cellType: UITableViewCell.self)) {
            (row, message, cell) in
            
            if let currentUser = SharingManager.defaultManager.currentUserInfo?.1 where
                message.senderID == currentUser.id {
                cell.textLabel?.textAlignment = .Right
                cell.textLabel?.text = message.text
            } else {
                cell.textLabel?.textAlignment = .Left
                cell.textLabel?.text = "\(message.senderID): \(message.text)"
            }
        }.addDisposableTo(viewModel.disposeBag)
        
        viewModel.messagesD.driveNext { [unowned self] _ in
            let offset = CGPointMake(0, self.tableView.contentSize.height-CGRectGetHeight(self.tableView.bounds))
            self.tableView.setContentOffset(offset, animated: true)
        }.addDisposableTo(viewModel.disposeBag)
        
        viewModel.reloadMessages()
    }
}
