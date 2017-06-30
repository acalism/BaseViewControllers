//
//  BaseTableViewController.swift
//  BaseViewControllers
//
//  Created by acalism on 16-8-4.
//  Copyright © 2016年 acalism. All rights reserved.
//


import UIKit



class BaseTableViewController: BaseScrollViewController, UITableViewDataSource, UITableViewDelegate {

    var tableView: UITableView!
    var clearsSelectionOnViewWillAppear: Bool = true

    let style: UITableViewStyle
    init(style: UITableViewStyle = .plain) {
        self.style = style
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        useDefaultScrollView = false

        super.loadView()

        tableView = UITableView(frame: view.bounds, style: style)
        tableView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        view.addSubview(tableView)

        scrollView = tableView

        tableView.backgroundColor = UIColor.clear
        tableView.separatorColor = UIColor(rgb: 0xF3F3F3)

        errorContentView = tableView.backgroundView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self // iOS 8 上会触发委托方法的调用
        tableView.delegate = self
        tableView.tableHeaderView = UIView() // 会触发计算 cell 高的委托方法的调用
        tableView.tableFooterView = UIView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 右滑返回时，deselect未自动生效的问题
        if let ip = tableView.indexPathForSelectedRow, clearsSelectionOnViewWillAppear {
            tableView.deselectRow(at: ip, animated: animated)
        }
    }

    override func clearContent(animated: Bool = false) {
        // Do nothing
    }
    override func loadContent(animated: Bool = false) {
        if animated {
            tableView.beginUpdates()
            tableView.reloadData()
            tableView.endUpdates()
        } else {
            tableView.reloadData()
        }
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tv: UITableView) -> Int {
        return 1
    }

    func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        fatalError("\(#function) must be overriden")
    }

    // MARK: - UITableViewDelegate

    // Override to support conditional editing of the table view.
    func tableView(_ tv: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }


    // Override to support editing the table view.
    func tableView(_ tv: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }



    // Override to support rearranging the table view.
    func tableView(_ tv: UITableView, moveRowAt fromIndexPath: IndexPath, to toIndexPath: IndexPath) {

    }

    // Override to support conditional rearranging of the table view.
    func tableView(_ tv: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return false
    }

    func tableView(_ tv: UITableView, didSelectRowAt indexPath: IndexPath) {
        //
    }
    func tableView(_ tv: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}
