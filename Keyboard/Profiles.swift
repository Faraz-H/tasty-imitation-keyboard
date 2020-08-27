////
////  Profile.swift
////  TastyImitationKeyboard
////
////  Created by Alexei Baboulevitch on 11/2/14.
////  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
////
//
//import UIKit
//import SQLite
//
//class Profiles: ExtraView, UITableViewDataSource, UITableViewDelegate {
//
//    @IBOutlet weak var NavBar: UINavigationItem!
//
//    @IBOutlet weak var deleteButton: UIBarButtonItem!
//    @IBOutlet weak var addButton: UIBarButtonItem!
//    @IBOutlet var tableView: UITableView?
//    @IBOutlet var effectsView: UIVisualEffectView?
//
//
//    @IBOutlet weak var keyboardButton: UIBarButtonItem!
//
//    @IBOutlet var settingsLabel: UILabel?
//    @IBOutlet var pixelLine: UIView?
//
//    @IBOutlet weak var editName: UIBarButtonItem!
//    //var callBack: () -> ()
//    @IBOutlet weak var profileViewButton: UIBarButtonItem!
//
//
//    override var darkMode: Bool {
//        didSet {
//            self.updateAppearance(darkMode)
//        }
//    }
//
//    let cellBackgroundColorDark = UIColor.white.withAlphaComponent(CGFloat(0.25))
//    let cellBackgroundColorLight = UIColor.white.withAlphaComponent(CGFloat(1))
//    let cellLabelColorDark = UIColor.white
//    let cellLabelColorLight = UIColor.black
//    let cellLongLabelColorDark = UIColor.lightGray
//    let cellLongLabelColorLight = UIColor.gray
//    var profileName:String?
//    // TODO: these probably don't belong here, and also need to be localized
//    var dataSourcesList: [(String, [String])]?
//    var deleteScreen:DeleteViewController?
//
//    required init(profileName: String, globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool) {
//        //self.callBack = tempCallBack
//        super.init(globalColors: globalColors, darkMode: darkMode, solidColorMode: solidColorMode)
//        self.loadNib()
//        self.profileName = profileName
//        var profiles: [String] = Database().getDataSources(target_profile: profileName)
//        self.NavBar.title = profileName
//        self.dataSourcesList = [("Data Sources", profiles)]
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("loading from nib not supported")
//    }
//
//    required init(globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool, outputFunc: () -> Void) {
//        fatalError("init(globalColors:darkMode:solidColorMode:outputFunc:) has not been implemented")
//    }
//
//    required init(globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool) {
//        fatalError("init(globalColors:darkMode:solidColorMode:) has not been implemented")
//    }
//
//    func loadNib() {
//        let assets = Bundle(for: type(of: self)).loadNibNamed("Profile", owner: self, options: nil)
//
//        if (assets?.count)! > 0 {
//            if let rootView = assets?.first as? UIView {
//                rootView.translatesAutoresizingMaskIntoConstraints = false
//                self.addSubview(rootView)
//
//                let left = NSLayoutConstraint(item: rootView, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.left, multiplier: 1, constant: 0)
//                let right = NSLayoutConstraint(item: rootView, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.right, multiplier: 1, constant: 0)
//                let top = NSLayoutConstraint(item: rootView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0)
//                let bottom = NSLayoutConstraint(item: rootView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0)
//
//                self.addConstraint(left)
//                self.addConstraint(right)
//                self.addConstraint(top)
//                self.addConstraint(bottom)
//            }
//        }
//        self.tableView?.register(ProfileTableViewCell.self, forCellReuseIdentifier: "cell")
//        self.tableView?.estimatedRowHeight = 44;
//        self.tableView?.rowHeight = UITableViewAutomaticDimension;
//
//        // XXX: this is here b/c a totally transparent background does not support scrolling in blank areas
//        self.tableView?.backgroundColor = UIColor.white.withAlphaComponent(0.01)
//
//        self.updateAppearance(self.darkMode)
//    }
//
//    func numberOfSections(in tableView: UITableView) -> Int {
//        return self.dataSourcesList!.count
//    }
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return self.dataSourcesList![section].1.count
//    }
//
//    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return 35
//    }
//
//    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
//        if section == (self.dataSourcesList?.count)! - 1 {
//            return 50
//        }
//        else {
//            return 0
//        }
//    }
//
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
//    {
//        return 80;//Choose your custom row height
//    }
//
//    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        return self.dataSourcesList?[section].0
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        if let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? ProfileTableViewCell {
//            let key = self.dataSourcesList?[(indexPath as NSIndexPath).section].1[(indexPath as NSIndexPath).row]
//
//            if cell.sw.allTargets.count == 0 {
//                cell.sw.addTarget(self, action: #selector(Profiles.toggleSetting(_:)), for: UIControlEvents.valueChanged)
//            }
//
//            //cell.sw.isOn = UserDefaults.standard.bool(forKey: key!)
//            //cell.sw.setTitle(title:", for: <#T##UIControlState#>)
//            cell.label.text = key!
//            cell.longLabel.text = nil
//
//            cell.backgroundColor = (self.darkMode ? cellBackgroundColorDark : cellBackgroundColorLight)
//            //cell.label.setTitleColor((self.darkMode ? cellLabelColorDark : cellLabelColorLight), for: UIControlState.normal)
//            cell.label.textColor = (self.darkMode ? cellLabelColorDark : cellLabelColorLight)
//            cell.longLabel.textColor = (self.darkMode ? cellLongLabelColorDark : cellLongLabelColorLight)
//            //cell.editingStyle = .delete
//            cell.changeConstraints()
//
//            return cell
//        }
//        else {
//            assert(false, "this is a bad thing that just happened")
//            return UITableViewCell()
//        }
//    }
//
//    func updateAppearance(_ dark: Bool) {
//        if dark {
//            self.effectsView?.effect
//            let blueColor = UIColor(red: 135/CGFloat(255), green: 206/CGFloat(255), blue: 250/CGFloat(255), alpha: 1)
//            self.pixelLine?.backgroundColor = blueColor.withAlphaComponent(CGFloat(0.5))
//            //self.keyboardButton?.setTitleColor(blueColor, for: UIControlState())
//            self.settingsLabel?.textColor = UIColor.white
//
//            if let visibleCells = self.tableView?.visibleCells {
//                for cell in visibleCells {
//                    cell.backgroundColor = cellBackgroundColorDark
//                    let label = cell.viewWithTag(2) as? UILabel
//                    label?.textColor = cellLabelColorDark
//                    let longLabel = cell.viewWithTag(3) as? UITextView
//                    longLabel?.textColor = cellLongLabelColorDark
//                }
//            }
//        }
//        else {
//            let blueColor = UIColor(red: 0/CGFloat(255), green: 122/CGFloat(255), blue: 255/CGFloat(255), alpha: 1)
//            self.pixelLine?.backgroundColor = blueColor.withAlphaComponent(CGFloat(0.5))
//            //self.keyboardButton?.setTitleColor(blueColor, for: UIControlState())
//            self.settingsLabel?.textColor = UIColor.gray
//
//            if let visibleCells = self.tableView?.visibleCells {
//                for cell in visibleCells {
//                    cell.backgroundColor = cellBackgroundColorLight
//                    let label = cell.viewWithTag(2) as? UILabel
//                    label?.textColor = cellLabelColorLight
//                    let longLabel = cell.viewWithTag(3) as? UITextView
//                    longLabel?.textColor = cellLongLabelColorLight
//                }
//            }
//        }
//    }
//
//    @objc func toggleSetting(_ sender: UISwitch) {
//        if let cell = sender.superview as? UITableViewCell {
//            if let indexPath = self.tableView?.indexPath(for: cell) {
//                let key = self.dataSourcesList?[(indexPath as NSIndexPath).section].1[(indexPath as NSIndexPath).row]
//                UserDefaults.standard.set(sender.isOn, forKey: key!)
//            }
//        }
//    }
//
//    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
//        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
//            //self.dataSourcesList![0].1.remove(at: indexPath.row)
//            //Database().removeDataSource(target_profile: self.profileName!, data_source: (self.dataSourcesList?[(indexPath as NSIndexPath).section].1[(indexPath as NSIndexPath).row])!)
//            let dataSource = (self.dataSourcesList?[(indexPath as NSIndexPath).section].1[(indexPath as NSIndexPath).row])!
//            self.deleteScreen = DeleteViewController(view: self as UIView, type: "data source", name: dataSource)
//            self.deleteScreen?.cancelButton.addTarget(self, action: #selector(self.removeDeleteScreen), for: .touchUpInside)
//            self.deleteScreen?.deleteButton.tag = (indexPath as NSIndexPath).row
//            self.deleteScreen?.deleteButton.addTarget(self, action: #selector(self.deleteDataSource(_:)), for: .touchUpInside)
//        }
//
//
//        return [delete]
//    }
//
//
//
//    @objc func removeDeleteScreen() {
//        if self.deleteScreen != nil {
//            self.deleteScreen?.warningView.removeFromSuperview()
//        }
//        self.tableView?.setEditing(false, animated: false)
//        self.deleteScreen = nil
//    }
//
//    @objc func deleteDataSource(_ sender:UIButton) {
//        let dataSource = (self.dataSourcesList?[0].1[sender.tag])!
////        Database().removeDataSource(target_profile: self.profileName!, data_source: dataSource)
//        removeDeleteScreen()
//        self.reloadData()
//    }
//
//    func reloadData() {
////        let profile: [String] = Database().getDataSources(target_profile: self.profileName!)
//        self.dataSourcesList = [("Data Sources", profile)]
//        tableView?.reloadData()
//    }
//
//}
//
//class ProfileTableViewCell: UITableViewCell {
//
//    var sw: UIButton
//    var label: UILabel
//    var longLabel: UITextView
//    var constraintsSetForLongLabel: Bool
//    var cellConstraints: [NSLayoutConstraint]
//
//    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
//        self.sw = UIButton()
//        self.label = UILabel()
//        self.longLabel = UITextView()
//        self.cellConstraints = []
//
//        self.constraintsSetForLongLabel = false
//
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//
//        self.sw.translatesAutoresizingMaskIntoConstraints = false
//        self.label.translatesAutoresizingMaskIntoConstraints = false
//        self.longLabel.translatesAutoresizingMaskIntoConstraints = false
//
//        self.longLabel.text = nil
//        self.longLabel.isScrollEnabled = false
//        self.longLabel.isSelectable = false
//        self.longLabel.backgroundColor = UIColor.clear
//
//        self.sw.tag = 1
//        self.label.tag = 2
//        self.longLabel.tag = 3
//
//        self.addSubview(self.sw)
//        self.addSubview(self.label)
//        self.addSubview(self.longLabel)
//
//        self.addConstraints()
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    func addConstraints() {
//        let margin: CGFloat = 8
//        let sideMargin = margin * 2
//
//        let hasLongText = self.longLabel.text != nil && !self.longLabel.text.isEmpty
//        if hasLongText {
//            let switchSide = NSLayoutConstraint(item: sw, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.right, multiplier: 1, constant: -sideMargin)
//            let switchTop = NSLayoutConstraint(item: sw, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.top, multiplier: 1, constant: margin)
//            let labelSide = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.left, multiplier: 1, constant: sideMargin)
//            let labelCenter = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: sw, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0)
//
//            self.addConstraint(switchSide)
//            self.addConstraint(switchTop)
//            self.addConstraint(labelSide)
//            self.addConstraint(labelCenter)
//
//            let left = NSLayoutConstraint(item: longLabel, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.left, multiplier: 1, constant: sideMargin)
//            let right = NSLayoutConstraint(item: longLabel, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.right, multiplier: 1, constant: -sideMargin)
//            let top = NSLayoutConstraint(item: longLabel, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: sw, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: margin)
//            let bottom = NSLayoutConstraint(item: longLabel, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: -margin)
//
//            self.addConstraint(left)
//            self.addConstraint(right)
//            self.addConstraint(top)
//            self.addConstraint(bottom)
//
//            self.cellConstraints += [switchSide, switchTop, labelSide, labelCenter, left, right, top, bottom]
//
//            self.constraintsSetForLongLabel = true
//        }
//        else {
//            let switchSide = NSLayoutConstraint(item: sw, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.right, multiplier: 1, constant: -sideMargin)
//            let switchTop = NSLayoutConstraint(item: sw, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.top, multiplier: 1, constant: margin)
//            let switchBottom = NSLayoutConstraint(item: sw, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: -margin)
//            let labelSide = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.left, multiplier: 1, constant: sideMargin)
//            let labelCenter = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: sw, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0)
//
//            self.addConstraint(switchSide)
//            self.addConstraint(switchTop)
//            self.addConstraint(switchBottom)
//            self.addConstraint(labelSide)
//            self.addConstraint(labelCenter)
//
//            self.cellConstraints += [switchSide, switchTop, switchBottom, labelSide, labelCenter]
//
//            self.constraintsSetForLongLabel = false
//        }
//    }
//
//    // XXX: not in updateConstraints because it doesn't play nice with UITableViewAutomaticDimension for some reason
//    func changeConstraints() {
//        let hasLongText = self.longLabel.text != nil && !self.longLabel.text.isEmpty
//        if hasLongText != self.constraintsSetForLongLabel {
//            self.removeConstraints(self.cellConstraints)
//            self.cellConstraints.removeAll()
//            self.addConstraints()
//        }
//    }
//
//    /*func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
//        return true
//    }
//
//    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
//        if (editingStyle == UITableViewCellEditingStyle.delete) {
//            // delete data and row
//            dataList.remove(at: indexPath.row)
//            tableView.deleteRows(at: [indexPath], with: .fade)
//        }
//    }*/
//}
