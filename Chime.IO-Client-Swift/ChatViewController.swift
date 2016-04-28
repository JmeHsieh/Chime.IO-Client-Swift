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

class ChatViewController: UITableViewController {
    
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
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier)
        tableView.allowsSelection = false
        tableView.rowHeight = 65.0
        tableView.separatorStyle = .None
        
        viewModel = ChatViewModel(roomID: roomID)
        viewModel.messagesOA.bindTo(tableView.rx_itemsWithCellIdentifier(CellIdentifier, cellType: UITableViewCell.self)) {
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
        viewModel.messagesOA.subscribe().addDisposableTo(viewModel.disposeBag)
    }
}
