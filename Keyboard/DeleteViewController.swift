//
//  File.swift
//  MeBoard
//
//  Created by Benjamin Katz on 12/9/16.
//  Copyright © 2016 Apple. All rights reserved.
//

import Foundation


import Foundation
import UIKit

class DeleteViewController:  UIViewController{
    
    let parentView:UIView
    var warningView:PassThroughView
    var warningTitle:UILabel
    var warningMessage:UILabel
    var cancelButton:UIButton
    var deleteButton:UIButton
    
    
    init(view: UIView, type:String, name:String)
    {
        self.parentView = view
        self.warningView = PassThroughView()
        self.warningTitle = UILabel()
        self.warningMessage = UILabel()
        self.cancelButton = UIButton()
        self.deleteButton = UIButton()
        
        super.init(nibName: nil, bundle: nil)
        let largeFont = CGFloat(30)
        let fontSize = CGFloat(22)
        
        self.warningView.layer.cornerRadius = 20
        self.warningView.backgroundColor = UIColor.white
        self.warningView.layer.borderColor = UIColor.gray.cgColor
        self.warningView.layer.borderWidth = 1
        self.warningView.isUserInteractionEnabled = true
        self.parentView.addSubview(self.warningView)
        self.parentView.bringSubview(toFront: self.warningView)

        self.warningTitle.font = UIFont.boldSystemFont(ofSize: largeFont)
        self.warningTitle.adjustsFontSizeToFitWidth = true
        self.warningTitle.textAlignment = .center
        self.warningTitle.text = "Warning"
        self.warningView.addSubview(self.warningTitle)
        
        
        self.warningMessage.font = UIFont.systemFont(ofSize: fontSize)
        self.warningMessage.textAlignment = .center
        self.warningMessage.adjustsFontSizeToFitWidth = true
        self.warningMessage.numberOfLines = 0
        self.warningMessage.text = "Are you sure you would like to delete the \(type):\n\(name)"
        self.warningView.addSubview(self.warningMessage)
        
        
        self.cancelButton.setTitle("Cancel", for: .normal)
        self.cancelButton.isEnabled = true
        self.cancelButton.isUserInteractionEnabled = true
        self.cancelButton.setTitleColor(UIColor.init(red: 20/255, green: 123/255, blue: 255/255, alpha: 1), for: UIControlState.normal)
        self.cancelButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: largeFont)
        self.warningView.addSubview(self.cancelButton)
        
        
        self.deleteButton.setTitle("Delete", for: .normal)
        self.deleteButton.setTitleColor(UIColor.red, for: UIControlState.normal)
        self.deleteButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: largeFont)
        self.warningView.addSubview(self.deleteButton)
        
        let warningViewWidth = (self.parentView.frame.maxX - self.parentView.frame.minX) * CGFloat(0.75)
        let warningViewHeight = (self.parentView.frame.maxY - self.parentView.frame.minY) * CGFloat(0.9)
        self.warningView.frame = CGRect(x: self.parentView.frame.midX - warningViewWidth / CGFloat(2), y: self.parentView.frame.midY - warningViewHeight / CGFloat(2), width: warningViewWidth, height: warningViewHeight)
        
        self.warningTitle.frame = CGRect(x: 0, y: 0, width: warningViewWidth, height: warningViewHeight / CGFloat(4))
        
        self.warningMessage.frame = CGRect(x: 0, y: self.warningTitle.frame.maxY, width: warningViewWidth, height: warningViewHeight / CGFloat(2))
        self.cancelButton.frame = CGRect(x: 0, y: self.warningMessage.frame.maxY, width: warningViewWidth / CGFloat(2), height: warningViewHeight / CGFloat(4))
        self.deleteButton.frame = CGRect(x: self.cancelButton.frame.maxX, y: self.warningMessage.frame.maxY, width: warningViewWidth / CGFloat(2), height: warningViewHeight / CGFloat(4))
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
