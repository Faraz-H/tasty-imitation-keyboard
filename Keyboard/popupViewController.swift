//
//  popupTableViewController.swift
//  TastyImitationKeyboard
//
//  Created by Benjamin Katz on 11/3/16.
//  Copyright © 2016 Apple. All rights reserved.
//

import Foundation
import UIKit
import SQLite

class PopUpViewController:  UIViewController,UITableViewDelegate, UITableViewDataSource {
    let popUpView = UIView()
    let tableView = UITableView()
    var selector: UIButton?
    var items: [String] = []
    //var addButton = UIButton()
    var editButton = UIButton()
    var callBack: () -> ()
    var maxHeight: CGFloat?
    let fontSize = CGFloat(22)
    init(selector: UIButton, maxHeight: CGFloat, callBack: @escaping () -> ())
    {
        self.callBack = callBack
        self.maxHeight = maxHeight
        super.init(nibName: nil, bundle: nil)
        self.selector = selector
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add all Profiles to items
//        items = Database().getProfiles()
        
        // Do any additional setup after loading the view, typically from a nib.
        tableView.rowHeight = 40
        let width = 300
        let maxNumRows: Int = Int(Double(maxHeight!) / Double(tableView.rowHeight))
        var numRows:Double = Double(items.count)
        if Double(maxNumRows) < numRows + 1 {
            numRows = Double(maxNumRows) - 1.5 //to make it clear that there is room to scroll
        }
        let height = Int(numRows * Double(self.tableView.rowHeight))//items.count * Int(self.tableView.rowHeight)
        
        
        tableView.frame         =   CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: width, height: height))
        self.preferredContentSize = CGSize(width: width, height: height + Int(tableView.rowHeight))
        tableView.delegate      =   self
        tableView.dataSource    =   self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        self.view.addSubview(tableView)
        
        /*
        addButton.frame = CGRect(x: 0, y: height, width: width / 2 - 1, height: Int(tableView.rowHeight))
        addButton.backgroundColor = UIColor.white
        addButton.setTitle("+", for: UIControlState())
        addButton.setTitleColor(UIColor.black, for: UIControlState())
        addButton.addTarget(self, action: #selector(dismissPopUp), for: .touchUpInside)
        self.view.addSubview(addButton)*/
        
        editButton.frame = CGRect(x: 0, y: height, width: width, height: Int(tableView.rowHeight))
        editButton.backgroundColor = UIColor.white
        editButton.setTitle("edit", for: UIControlState())
        editButton.setTitleColor(UIColor.black, for: UIControlState())
        editButton.addTarget(self, action: #selector(dismissPopUp), for: .touchUpInside)
        editButton.backgroundColor = UIColor.lightGray.withAlphaComponent(0.7)
        self.view.addSubview(editButton)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        let text = self.items[indexPath.row]
        cell.textLabel?.text = text
        cell.textLabel?.font = UIFont.systemFont(ofSize: fontSize)
        if text == selector?.titleLabel!.text! {
            cell.backgroundColor = UIColor.init(red: 242/255, green: 193/255, blue: 133/255, alpha: 1)
        }
        else {
            cell.backgroundColor = UIColor.white
        }
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let newSelection = self.items[indexPath.row]
        selector?.setTitle(newSelection, for: UIControlState())
        UserDefaults.standard.register(defaults: ["profile": newSelection])
        dismissPopUp()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func dismissPopUp(){
        self.dismiss(animated: true, completion: nil)
        self.callBack()
    }
    
    
}

