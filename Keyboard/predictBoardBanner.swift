//
//  predictboardBanner.swift
//  TastyImitationKeyboard
//
//  Created by Alexei Baboulevitch on 10/5/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import UIKit

/*
 This is the demo banner. The banner is needed so that the top row popups have somewhere to go. Might as well fill it
 with something (or leave it blank if you like.)
 */

class PredictboardBanner: ExtraView {

    let numButtons = UserDefaults.standard.integer(forKey: "numberACSbuttons")
    let allButtons = UserDefaults.standard.integer(forKey: "numberACSbuttons")
    let numRows = UserDefaults.standard.integer(forKey: "numberACSrows")
    var buttons = [BannerButton]()
    let profileSelector = BannerButton()
    let phraseSelector = BannerButton()
    let defaultView = PassThroughView()
    let textInputView = PassThroughView()
    let loadingView = PassThroughView()
    let textField = keyboardTextField()
    let textFieldLabel = UILabel()
    let backButton = UIButton()
    let saveButton = UIButton()
    let pasteButton = UIButton()
    let clearButton = UIButton()
    let loadingLabel = UILabel()
    let loadingLabelMessage = UILabel()
    var tiButtons = [BannerButton]()
    let numTIbuttons = 5
    var setCaps:() -> (Bool)

    let warningView = UIView()
    let warningTitle = UILabel()
    let warningMessage = UILabel()
    let warningButton = UIButton()

    let progressBar = UIProgressView()
    var counter:Int = 0 {
        didSet {
            let fractionalProgress = Float(counter) / 100.0
            let animated = counter != 0

            self.progressBar.setProgress(fractionalProgress, animated: animated)
        }
    }

    required init(setCaps:@escaping () -> (Bool), globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool) {
        let defaults = UserDefaults.standard
        self.setCaps = setCaps
        super.init(globalColors: globalColors, darkMode: darkMode, solidColorMode: solidColorMode)

        defaultView.frame = CGRect(x: self.getMinX(), y: self.getMinY(), width: self.frame.width, height: self.frame.height)
        self.addSubview(defaultView)
        defaultView.isHidden = true

        textInputView.frame = CGRect(x: self.getMinX(), y: self.getMinY(), width: self.frame.width, height: self.frame.height)
//        self.addSubview(textInputView)
//        textInputView.isHidden = true

        loadingView.frame = CGRect(x: self.getMinX(), y: self.getMinY(), width: self.frame.width, height: self.frame.height)
        self.addSubview(loadingView)
        loadingView.isHidden = false

        //if textField is selected, we cant type on the main app anymore
        self.textField.isUserInteractionEnabled = false

        let largeFont = CGFloat(30)
        let fontSize = CGFloat(20)

        for i in 0..<(self.numButtons/* + self.numTIbuttons*/) {
            let button: BannerButton = BannerButton()
            button.type = "ACButton"
            if i < self.numButtons {
                buttons.append(button)
                defaultView.addSubview(button)
            }
            else {
                self.tiButtons.append(button)
                textInputView.addSubview(button)
            }
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.clear.cgColor
            button.layer.cornerRadius = 6 // round the corner of button
            button.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.addTarget(self, action: #selector(buttonClicked), for: .touchDown)
            button.addTarget(self, action: #selector(buttonClicked), for: .touchDragEnter)
            button.addTarget(self, action: #selector(buttonUnclicked), for: .touchDragExit)
            button.addTarget(self, action: #selector(buttonUnclicked), for: .touchUpInside)

        }

        //add profile selector button
//        self.profileSelector.type = "SelectorButton"
//        defaultView.addSubview(self.profileSelector)
//        self.profileSelector.titleLabel?.adjustsFontSizeToFitWidth = true
//        self.profileSelector.layer.borderWidth = 1
//        self.profileSelector.layer.cornerRadius = 5
//        self.profileSelector.layer.borderColor = UIColor.clear.cgColor
//        self.profileSelector.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
//        self.profileSelector.addTarget(self, action: #selector(buttonClicked), for: .touchDown)
//        self.profileSelector.addTarget(self, action: #selector(buttonClicked), for: .touchDragEnter)
//        self.profileSelector.addTarget(self, action: #selector(buttonUnclicked), for: .touchDragExit)
//        self.profileSelector.addTarget(self, action: #selector(buttonUnclicked), for: .touchUpInside)

//        self.phraseSelector.type = "SelectorButton"
//        defaultView.addSubview(self.phraseSelector)
//        self.phraseSelector.titleLabel?.adjustsFontSizeToFitWidth = true
//        self.phraseSelector.layer.borderWidth = 1
//        self.phraseSelector.layer.cornerRadius = 5
//        self.phraseSelector.layer.borderColor = UIColor.clear.cgColor
//        self.phraseSelector.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
//        self.phraseSelector.addTarget(self, action: #selector(buttonClicked), for: .touchDown)
//        self.phraseSelector.addTarget(self, action: #selector(buttonClicked), for: .touchDragEnter)
//        self.phraseSelector.addTarget(self, action: #selector(buttonUnclicked), for: .touchDragExit)
//        self.phraseSelector.addTarget(self, action: #selector(buttonUnclicked), for: .touchUpInside)
//        self.phraseSelector.setTitle("Phrases", for: .normal)

        //self.textField.placeholder = "Just Start Typing"
        self.textField.font = UIFont.systemFont(ofSize: fontSize)
        self.textField.lineBreakMode = .byTruncatingHead
        self.textField.layer.borderWidth = 1
        self.textField.layer.cornerRadius = 5
        self.textField.layer.borderColor = UIColor.black.cgColor
        //self.textField.borderStyle = UITextBorderStyle.roundedRect
        //self.textField.autocorrectionType = UITextAutocorrectionType.no
        //self.textField.returnKeyType = UIReturnKeyType.done
        //self.textField.clearButtonMode = UITextFieldViewMode.whileEditing;
        //self.textField.contentVerticalAlignment = UIControlContentVerticalAlignment.center
        self.textField.backgroundColor = UIColor.white
        //self.textField.adjustsFontSizeToFitWidth = true
        self.textInputView.addSubview(self.textField)

        //self.textFieldLabel.text = "Profile Name:"
        self.textFieldLabel.textAlignment = .right
        self.textFieldLabel.font = UIFont.systemFont(ofSize: fontSize)
        self.textInputView.addSubview(self.textFieldLabel)

        self.backButton.setTitle("Cancel", for: UIControlState())
        self.backButton.layer.cornerRadius = 5
        self.backButton.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
        self.textInputView.addSubview(self.backButton)


        self.saveButton.setTitle("Save", for: UIControlState())
        self.saveButton.layer.cornerRadius = 5
        self.saveButton.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
        self.textInputView.addSubview(self.saveButton)

        self.pasteButton.setTitle("Paste", for: UIControlState())
        self.pasteButton.layer.cornerRadius = 5
        self.pasteButton.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
        self.textInputView.addSubview(self.pasteButton)
        self.pasteButton.addTarget(self, action: #selector(pasteInTextbox), for: .touchUpInside)

        self.clearButton.setTitle("Clear", for: UIControlState())
        self.clearButton.layer.cornerRadius = 5
        self.clearButton.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
        self.textInputView.addSubview(self.clearButton)
        self.clearButton.addTarget(self, action: #selector(clearTextbox), for: .touchUpInside)

        self.warningView.layer.cornerRadius = 20
        self.warningView.backgroundColor = UIColor.white
        self.warningView.layer.borderColor = UIColor.gray.cgColor
        self.warningView.layer.borderWidth = 1
        self.textInputView.addSubview(self.warningView)

        self.warningTitle.font = UIFont.boldSystemFont(ofSize: largeFont)
        self.warningTitle.adjustsFontSizeToFitWidth = true
        self.warningTitle.textAlignment = .center
        self.warningView.addSubview(self.warningTitle)


        self.warningMessage.font = UIFont.systemFont(ofSize: fontSize)
        self.warningMessage.textAlignment = .center
        self.warningTitle.adjustsFontSizeToFitWidth = true
        self.warningMessage.numberOfLines = 0
        self.warningView.addSubview(self.warningMessage)


        self.warningButton.setTitle("OK", for: .normal)
        self.warningButton.setTitleColor(UIColor.init(red: 20/255, green: 123/255, blue: 255/255, alpha: 1), for: UIControlState.normal)
        self.warningButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: largeFont)
        self.warningView.addSubview(self.warningButton)
        self.warningButton.addTarget(self, action: #selector(hideWarningView), for: .touchUpInside)

        self.loadingLabel.text = "Loading Predictions"
        self.loadingLabel.textAlignment = .center
        self.loadingLabel.font = UIFont.systemFont(ofSize: 16)
        self.loadingView.addSubview(self.loadingLabel)

        self.loadingLabelMessage.textAlignment = .center
        self.loadingLabelMessage.font = UIFont.systemFont(ofSize: fontSize)
        self.loadingView.addSubview(self.loadingLabelMessage)

        self.loadingView.addSubview(progressBar)

        hideWarningView()
        updateAppearance()

        UserDefaults.standard.register(defaults: ["keyboardInputToApp": true])
    }


    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool) {
        fatalError("init(globalColors:darkMode:solidColorMode:) has not been implemented")
    }


    override func setNeedsLayout() {
        super.setNeedsLayout()
    }


    override func layoutSubviews() {
        super.layoutSubviews()



        let widthBut = (self.getMaxX() - self.getMinX()) / CGFloat(self.allButtons) * CGFloat(self.numRows)
        let heightBut = (self.getMaxY() - self.getMinY()) / CGFloat(self.numRows)
        //let halfWidth = widthBut / CGFloat(2)

        var x_offset = CGFloat(0)
        var y_offset = CGFloat(0)
        var row = 0
        var buttonIndex = 0
        for index in 0..<self.allButtons {
            /*
            if row == 0 && index + 1 == self.allButtons / self.numRows {
                self.profileSelector.frame = CGRect(x: (self.getMinX() + x_offset), y: self.getMinY() + y_offset, width: widthBut - 1, height: heightBut - 1)
            }
            else if row == 0 && index == 0 {
                self.phraseSelector.frame = CGRect(x: (self.getMinX() + x_offset), y: self.getMinY() + y_offset, width: widthBut - 1, height: heightBut - 1)
            }
            else{
            */
                buttons[buttonIndex].frame = CGRect(x: (self.getMinX() + x_offset), y: self.getMinY() + y_offset, width: widthBut - 1, height: heightBut - 1)
                buttonIndex += 1
            //}
            x_offset += widthBut
            if (index + 1) % (self.allButtons / self.numRows) == 0 {
                y_offset += heightBut
                x_offset = CGFloat(0)
                row += 1
            }
        }

        let rowSize:CGFloat = self.getMaxX() - self.getMinX()
        let labelSpacing:CGFloat = 8
        let textWidth = rowSize * CGFloat(0.75) - labelSpacing * 2
        let labelWidth = rowSize * CGFloat(0.25)
        let textHeight:CGFloat = 40
        let rowSpacing:CGFloat = 3
        let viewThird = self.getMinY() + (self.getMaxY() - self.getMinY()) / CGFloat(3)
        let textFieldY = viewThird + rowSpacing

        self.textFieldLabel.frame = CGRect(x: 0, y: textFieldY, width: labelWidth, height: textHeight)

        self.textField.frame = CGRect(x: self.textFieldLabel.frame.maxX + labelSpacing, y: self.textFieldLabel.frame.minY, width: textWidth, height: textHeight)



        let actionButWidth:CGFloat = 75
        let actionButHeight:CGFloat = 40
        let actionButtonSpacing:CGFloat = (rowSize - actionButWidth * 4) / 5

        let actionButtonY = rowSpacing

        self.backButton.frame = CGRect(x: actionButtonSpacing, y: actionButtonY, width: actionButWidth, height: actionButHeight)
        self.clearButton.frame = CGRect(x: self.backButton.frame.maxX + actionButtonSpacing, y: actionButtonY, width: actionButWidth, height: actionButHeight)
        self.pasteButton.frame = CGRect(x: self.clearButton.frame.maxX + actionButtonSpacing, y: actionButtonY, width: actionButWidth, height: actionButHeight)
        self.saveButton.frame = CGRect(x: self.pasteButton.frame.maxX + actionButtonSpacing, y: actionButtonY, width: actionButWidth, height: actionButHeight)

        let tiButtonY = viewThird * CGFloat(2)
        var tiButtonX:CGFloat = 0
        for button in tiButtons {
            button.frame = CGRect(x: tiButtonX, y: tiButtonY, width: widthBut - 1, height: heightBut - 1)
            tiButtonX += widthBut
        }


        let warningViewWidth = (self.getMaxX() - self.getMinX()) * CGFloat(0.75)
        let warningViewHeight = (self.getMaxY() - self.getMinY()) * CGFloat(0.9)
        self.warningView.frame = CGRect(x: self.getMidX() - warningViewWidth / CGFloat(2), y: self.getMidY() - warningViewHeight / CGFloat(2), width: warningViewWidth, height: warningViewHeight)

        self.warningTitle.frame = CGRect(x: 0, y: 0, width: warningViewWidth, height: warningViewHeight / CGFloat(3))

        self.warningMessage.frame = CGRect(x: 0, y: self.warningTitle.frame.maxY, width: warningViewWidth, height: warningViewHeight / CGFloat(3))
        self.warningButton.frame = CGRect(x: 0, y: self.warningMessage.frame.maxY, width: warningViewWidth, height: warningViewHeight / CGFloat(3))

        self.loadingLabel.frame = CGRect(x: self.getMidX() - textWidth, y: self.getMidY() - textHeight / CGFloat(2), width: 2 * textWidth, height: textHeight)

        self.loadingLabelMessage.frame = CGRect(x: self.loadingLabel.frame.origin.x, y: self.loadingLabel.frame.maxY + rowSpacing, width: self.loadingLabel.frame.width, height: self.loadingLabel.frame.height)

        self.progressBar.setProgress(0, animated: true)
        self.progressBar.frame = CGRect(x: self.getMidX() - textWidth/2.0, y: self.getMidY() + CGFloat(2.5) * textHeight / CGFloat(6), width: textWidth, height: textHeight*0.33)

    }

    override func updateAppearance()
    {
        var allButtons: [UIButton] = self.buttons + self.tiButtons
        allButtons.append(self.backButton)
        allButtons.append(self.saveButton)
        allButtons.append(self.pasteButton)
        allButtons.append(self.clearButton)

        for button in allButtons{
            //button.backgroundColor = globalColors?.specialKey(darkMode, solidColorMode: solidColorMode)
//            button.setTitleColor((self.globalColors?.darkModeTextColor), for: UIControlState.normal)
          button.setTitleColor((darkMode ? self.globalColors?.darkModeTextColor : self.globalColors?.lightModeTextColor), for: UIControlState.normal)
            // set banner font color to black
          //button.setTitleColor(UIColor.black, for: .normal)
          //button.setTitleColor(.d, for: .normal)
        }


        self.profileSelector.backgroundColor = globalColors?.regularKey(darkMode, solidColorMode: solidColorMode)
        self.profileSelector.setTitleColor((darkMode ? self.globalColors?.darkModeTextColor : self.globalColors?.lightModeTextColor), for: UIControlState.normal)
        self.profileSelector.setTitleColor(self.globalColors?.darkModeTextColor, for: UIControlState.highlighted)

        self.phraseSelector.backgroundColor = globalColors?.regularKey(darkMode, solidColorMode: solidColorMode)
        self.phraseSelector.setTitleColor((darkMode ? self.globalColors?.darkModeTextColor : self.globalColors?.lightModeTextColor), for: UIControlState.normal)
        self.phraseSelector.setTitleColor(self.globalColors?.darkModeTextColor, for: UIControlState.highlighted)

        self.textFieldLabel.textColor = (darkMode ? self.globalColors?.darkModeTextColor : self.globalColors?.lightModeTextColor)
        self.loadingLabel.textColor = (darkMode ? self.globalColors?.darkModeTextColor : self.globalColors?.lightModeTextColor)
    }


    @objc func buttonClicked(_ sender:BannerButton){
        if sender.type == "ACButton" {
//            sender.backgroundColor = globalColors?.regularKey(darkMode, solidColorMode: solidColorMode)
            // after pressing the button, the button color changes
            sender.backgroundColor = UIColor.white.withAlphaComponent(0.5)

            if (sender == buttons[0]) {
                KeyboardViewController.shared!.bannerButnOnePressed()
            }
            else if (sender == buttons[1]) {
                KeyboardViewController.shared!.bannerButnTwoPressed()
            }
            else if (sender == buttons[2]) {
                KeyboardViewController.shared!.bannerButnThreePressed()
            }
        }
        else if sender.type == "SelectorButton" {
            sender.backgroundColor = globalColors?.specialKey(darkMode, solidColorMode: solidColorMode)
        }
    }

    @objc func buttonUnclicked(_ sender:BannerButton){
        if sender.type == "ACButton" {
            sender.backgroundColor = globalColors?.specialKey(darkMode, solidColorMode: solidColorMode)

            if (sender == buttons[0]) {
                KeyboardViewController.shared!.bannerButnOneUp()
            }
            else if (sender == buttons[1]) {
                KeyboardViewController.shared!.bannerButnTwoUp()
            }
            else if (sender == buttons[2]) {
                KeyboardViewController.shared!.bannerButnThreeUp()
            }
        }
        else if sender.type == "SelectorButton" {
            sender.backgroundColor = globalColors?.regularKey(darkMode, solidColorMode: solidColorMode)
        }
    }

    func selectDefaultView() {
        UserDefaults.standard.register(defaults: ["keyboardInputToApp": true])
        switchView()
    }

    func selectTextView() {
        self.textField.text = ""
        UserDefaults.standard.register(defaults: ["keyboardInputToApp": false])
        switchView()
    }

    func showLoadingScreen(toShow: Bool) {
        self.loadingLabelMessage.text = ""
        self.loadingView.isHidden = !toShow
        self.defaultView.isHidden = toShow
        self.defaultView.isUserInteractionEnabled = !toShow
    }


    func switchView(){
        if UserDefaults.standard.bool(forKey: "keyboardInputToApp") == true {
            self.bringSubview(toFront: self.defaultView)
            self.defaultView.isHidden = false
            self.defaultView.isUserInteractionEnabled = true
            self.textInputView.isHidden = true
            self.textInputView.isUserInteractionEnabled = false
            self.setCaps()
        }
        else {
            self.bringSubview(toFront: self.textInputView)
            self.textInputView.isHidden = false
            self.textInputView.isUserInteractionEnabled = true
            self.defaultView.isHidden = true
            self.defaultView.isUserInteractionEnabled = false
            self.setCaps()
        }
    }

    @objc func pasteInTextbox() {
        if let pasteString = UIPasteboard.general.string {
            self.textField.text? += String(pasteString)

        }

    }

    func emptyTextbox() -> Bool {
        if self.textField.text == "" {
            showWarningView(title: "Warning", message: "No input given")
            return true
        }
        return false
    }


    @objc func clearTextbox() {
        self.textField.text = ""
    }

    @objc func hideWarningView() {
        self.warningView.isUserInteractionEnabled = false
        self.warningView.isHidden = true
    }

    func showWarningView(title: String, message: String) {
        self.warningTitle.text = title
        self.warningMessage.text = message
        self.warningView.isUserInteractionEnabled = true
        self.warningView.isHidden = false
    }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)

    self.updateAppearance()
  }
}


class keyboardTextField: UILabel {
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets.init(top: 0, left: 5, bottom: 0, right: 5)
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }
}
