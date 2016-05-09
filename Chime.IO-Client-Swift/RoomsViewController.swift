//
//  RoomsViewController.swift
//  Chime.IO-Client-Swift
//
//  Created by JmeHsieh on 4/27/16.
//  Copyright © 2016 JmeHsieh. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit

class RoomsViewController: UITableViewController {
    
    var refreshButton: UIBarButtonItem!
    var spinner: UIBarButtonItem!
    
    private let disposeBag = DisposeBag()
    var viewModel: RoomsViewModel!
    
    // MARK: - Constructors
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup views
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "CellIdentifier")
        tableView.rowHeight = 88.0

        refreshButton = UIBarButtonItem()
        refreshButton.title = "Refresh"
        let _spinner = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        _spinner.startAnimating()
        spinner = UIBarButtonItem(customView: _spinner)
        self.navigationItem.rightBarButtonItem = refreshButton
        
        // rx
        viewModel = RoomsViewModel(refreshButton.rx_tap.asDriver())
        viewModel.isloadingD.driveNext { [unowned self] in
            self.navigationItem.rightBarButtonItem = $0 ? self.spinner : self.refreshButton
        }.addDisposableTo(disposeBag)
        
        viewModel.roomsOA.bindTo(tableView.rx_itemsWithCellIdentifier("CellIdentifier")) { (row, room, cell) in
            cell.textLabel?.text = room.id
            cell.accessoryType = .DisclosureIndicator
        }.addDisposableTo(disposeBag)
        
        tableView.rx_modelSelected(Room).subscribeNext { [unowned self] in
            print("room: \($0.id) tapped")
            self.navigationController?.pushViewController(ChatViewController(roomID: $0.id), animated: true)
        }.addDisposableTo(disposeBag)
        
        tableView.rx_itemSelected.subscribeNext { [unowned self] in
            self.tableView.deselectRowAtIndexPath($0, animated: true)
        }.addDisposableTo(disposeBag)
        
        // first load
        viewModel.reload()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}