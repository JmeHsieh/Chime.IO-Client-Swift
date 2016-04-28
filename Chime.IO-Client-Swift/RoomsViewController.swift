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
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "CellIdentifier")
        
        refreshButton = UIBarButtonItem()
        refreshButton.title = "Refresh"
        let _spinner = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        _spinner.startAnimating()
        spinner = UIBarButtonItem(customView: _spinner)
        self.navigationItem.rightBarButtonItem = refreshButton
        
        viewModel = RoomsViewModel(refreshButton.rx_tap.asDriver())
        viewModel.isloadingD.driveNext { [unowned self] in
            self.navigationItem.rightBarButtonItem = $0 ? self.spinner : self.refreshButton
        }.addDisposableTo(viewModel.disposeBag)
        
        viewModel.roomsOA.bindTo(tableView.rx_itemsWithCellIdentifier("CellIdentifier")) { (row, room, cell) in
            cell.textLabel?.text = room.id
        }.addDisposableTo(viewModel.disposeBag)
        
        tableView.rx_modelSelected(Room).subscribeNext { [unowned self] in
            print("room: \($0.id) tapped")
        }.addDisposableTo(viewModel.disposeBag)
        
        tableView.rx_itemSelected.subscribeNext { [unowned self] in
            self.tableView.deselectRowAtIndexPath($0, animated: true)
        }.addDisposableTo(viewModel.disposeBag)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

//    var _rooms = [Room]()
//    var rooms: [Room] {
//        get { return _rooms }
//        set(nrs) {
//            var rs = nrs
//            rs.sortInPlace {
//                $0.createdAt!.compare($1.createdAt!) == NSComparisonResult.OrderedAscending
//            }
//            _rooms = rs
//        }
//    }
//
//
//    // MARK: - View Lifecycle
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        self
//        ChimeIOAPI.sharedInstance.getMyRooms().then(on: dispatch_get_main_queue()) { rooms -> Void in
//            self.rooms = rooms
//            self.tableView.reloadData()
//        }
//    }
//    
//    override func didReceiveMemoryWarning() {
//        
//    }
//    
//    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
//        return 1
//    }
//    
//    // MARK: - UITableViewDataSource
//    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return rooms.count
//    }
//    
//    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//        let CellIdentifier = "CellIdentifier"
//        var cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier)
//        if cell == nil {
//            cell = UITableViewCell(style: .Subtitle, reuseIdentifier: CellIdentifier)
//            cell?.accessoryType = .DisclosureIndicator
//        }
//        cell?.textLabel!.text = rooms[indexPath.row].id
//        return cell!
//    }
//    
//    // MARK: - UITableViewDelegate
//    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        return 80.0
//    }
//    
//    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        tableView.deselectRowAtIndexPath(indexPath, animated: true)
//    }
}