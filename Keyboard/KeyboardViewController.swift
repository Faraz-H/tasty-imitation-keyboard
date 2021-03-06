//
//  KeyboardViewController.swift
//  Keyboard
//
//  Created by Alexei Baboulevitch on 6/9/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import UIKit
import AudioToolbox
import BridgeSDK
import Firebase

let metrics: [String:Double] = [
    "topBanner": Double(45 * UserDefaults.standard.integer(forKey: "numberACSrows"))
]
func metric(_ name: String) -> CGFloat { return CGFloat(metrics[name]!) }

// TODO: move this somewhere else and localize
let kAutoCapitalization = "kAutoCapitalization"
let kPeriodShortcut = "kPeriodShortcut"
let kKeyboardClicks = "kKeyboardClicks"
let kSmallLowercase = "kSmallLowercase"

let keyloggerAdapter = KeyloggerAdapter.sharedInstance

class KeyboardViewController: UIInputViewController, SBBAuthManagerDelegateProtocol {

    static var shared: KeyboardViewController? = nil

    var globeKeyShouldDisplay = true

    let backspaceDelay: TimeInterval = 0.5
    let backspaceRepeat: TimeInterval = 0.15
    
    let secondaryTextDelay: TimeInterval = 0.5
    
    let lineView = UIView()
    let lineViewSec = UIView()
    
    var keyboard: Keyboard!
    var forwardingView: ForwardingView!
    var layout: KeyboardLayout?
    var heightConstraint: NSLayoutConstraint?
    
    var bannerView: ExtraView?
    var settingsView: ExtraView?
    //var profileView: ExtraView?
    var currentKey: KeyboardKey?
    
    var currentMode: Int {
        didSet {
            if oldValue != currentMode {
                setMode(currentMode)
            }
        }
    }
    
    var backspaceActive: Bool {
        get {
            return (backspaceDelayTimer != nil) || (backspaceRepeatTimer != nil)
        }
    }
    var backspaceDelayTimer: Timer?
    var backspaceRepeatTimer: Timer?
    
    var secondaryTextTimer: Timer?
    var secondaryTextMode: Bool = false
    
    enum AutoPeriodState {
        case noSpace
        case firstSpace
    }
    
    var autoPeriodState: AutoPeriodState = .noSpace
    var lastCharCountInBeforeContext: Int = 0
    
    var shiftState: ShiftState {
        didSet {
            switch shiftState {
            case .disabled:
                self.updateKeyCaps(false)
            case .enabled:
                self.updateKeyCaps(true)
            case .locked:
                self.updateKeyCaps(true)
            }
        }
    }
    
    // state tracking during shift tap
    var shiftWasMultitapped: Bool = false
    var shiftStartingState: ShiftState?
    
    var keyboardHeight: CGFloat {
        get {
            if let constraint = self.heightConstraint {
                return constraint.constant
            }
            else {
                return 0
            }
        }
        set {
            self.setHeight(newValue)
        }
    }
  
    static var firebaseInitialized = false
    
    func configureFirebase () {
      if Self.firebaseInitialized {
        return
      }
      FirebaseApp.configure()
      Self.firebaseInitialized = true
    }
      
    // TODO: why does the app crash if this isn't here?
    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        let appGroupID = "group.com.Meboard"
        UserDefaults(suiteName: appGroupID)
        UserDefaults.standard.register(defaults: [
            kAutoCapitalization: true,
            kPeriodShortcut: true,
            kKeyboardClicks: true,
            kSmallLowercase: true,
            "numberACSrows": 1,
            "numberACSbuttons": 3
        ])
        let appDefaults = [String:AnyObject]()
        UserDefaults.standard.register(defaults: appDefaults)
        
        self.shiftState = .disabled
        self.currentMode = 0
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        //Fabric.with([Crashlytics.self])
        configureFirebase()

        self.forwardingView = ForwardingView(frame: CGRect.zero)
        self.view.addSubview(self.forwardingView)
        
        KeyboardViewController.shared = self
        
        //Detect if the device is iphone X/XS...
        if UIDevice().userInterfaceIdiom == .phone {
            if (UIScreen.main.nativeBounds.height == 2436 || UIScreen.main.nativeBounds.height == 2688
                || UIScreen.main.nativeBounds.height == 1792) {
                self.globeKeyShouldDisplay = false
            }
        }
        
        self.keyboard = defaultKeyboard()
        
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardViewController.defaultsChanged(_:)), name: UserDefaults.didChangeNotification, object: nil)
        KeyboardViewController.shared = self
        self.setupBridgeStudy()
    }
    
    required convenience init?(coder: NSCoder) {
        self.init(nibName: nil, bundle: nil)
    }
    
    deinit {
        backspaceDelayTimer?.invalidate()
        backspaceRepeatTimer?.invalidate()
        secondaryTextTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupBridgeStudy() {
        // Set up using default BridgeInfo.plist and BridgeInfo-private.plist, and no errorUIDelegate.
        BridgeSDK.setup()

        // Set ourselves as the auth delegate to handle storing and serving login credentials and session tokens.
        // The code for this duplicates the relevant parts of how the auth delegate works in BridgeAppSDK.
//        BridgeSDK.setAuthDelegate(self) // remove this, because BridgeSDK no longer support this method
    }
    
    @objc func defaultsChanged(_ notification: Notification) {
        //let defaults = notification.object as? NSUserDefaults
        self.updateKeyCaps(self.shiftState.uppercase())
    }
    
    // without this here kludge, the height constraint for the keyboard does not work for some reason
    var kludge: UIView?
    func setupKludge() {
        if self.kludge == nil {
            let kludge = UIView()
            self.view.addSubview(kludge)
            kludge.translatesAutoresizingMaskIntoConstraints = false
            kludge.isHidden = true
            
            let a = NSLayoutConstraint(item: kludge, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.left, multiplier: 1, constant: 0)
            let b = NSLayoutConstraint(item: kludge, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.left, multiplier: 1, constant: 0)
            let c = NSLayoutConstraint(item: kludge, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0)
            let d = NSLayoutConstraint(item: kludge, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0)
            self.view.addConstraints([a, b, c, d])
            
            self.kludge = kludge
        }
    }
    
    /*
    BUG NOTE

    For some strange reason, a layout pass of the entire keyboard is triggered 
    whenever a popup shows up, if one of the following is done:

    a) The forwarding view uses an autoresizing mask.
    b) The forwarding view has constraints set anywhere other than init.

    On the other hand, setting (non-autoresizing) constraints or just setting the
    frame in layoutSubviews works perfectly fine.

    I don't really know what to make of this. Am I doing Autolayout wrong, is it
    a bug, or is it expected behavior? Perhaps this has to do with the fact that
    the view's frame is only ever explicitly modified when set directly in layoutSubviews,
    and not implicitly modified by various Autolayout constraints
    (even though it should really not be changing).
    */
    
    var constraintsAdded: Bool = false
    func setupLayout() {
        if !constraintsAdded {
            self.layout = type(of: self).layoutClass.init(model: self.keyboard, superview: self.forwardingView, layoutConstants: type(of: self).layoutConstants, globalColors: type(of: self).globalColors, darkMode: self.darkMode(), solidColorMode: self.solidColorMode())
          debugPrint(self.darkMode())
            self.layout?.initialize()
            self.setMode(0)
            
            self.setupKludge()
            
            self.updateKeyCaps(self.shiftState.uppercase())
            var capsWasSet = self.setCapsIfNeeded()
            
            self.updateAppearances(self.darkMode())
            self.addInputTraitsObservers()
            
            self.constraintsAdded = true
        }
    }
    
    // only available after frame becomes non-zero
    func darkMode() -> Bool {
      if #available(iOSApplicationExtension 12.0, *) {
        return self.traitCollection.userInterfaceStyle == .dark
      } else {
        // Fallback on earlier versions
 
        let darkMode = { () -> Bool in
            let proxy = self.textDocumentProxy
            return proxy.keyboardAppearance == UIKeyboardAppearance.dark
        }()
        
        return darkMode
      }
    }
    
    func solidColorMode() -> Bool {
        return UIAccessibilityIsReduceTransparencyEnabled()
    }
    
    var lastLayoutBounds: CGRect?
    override func viewDidLayoutSubviews() {
        if view.bounds == CGRect.zero {
            return
        }
        
        self.setupLayout()
        
        let orientationSavvyBounds = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.heightForOrientation(self.interfaceOrientation, withTopBanner: false))
        
        if (lastLayoutBounds != nil && lastLayoutBounds == orientationSavvyBounds) {
            // do nothing
        }
        else {
            let uppercase = self.shiftState.uppercase()
            let characterUppercase = (UserDefaults.standard.bool(forKey: kSmallLowercase) ? uppercase : true)
            
            self.forwardingView.frame = orientationSavvyBounds
            self.layout?.layoutKeys(self.currentMode, uppercase: uppercase, characterUppercase: characterUppercase, shiftState: self.shiftState)
            self.lastLayoutBounds = orientationSavvyBounds
            self.setupKeys()
        }
        
        self.bannerView?.frame = CGRect(x: 0, y: metric("topBanner") * 0.1, width: self.view.bounds.width, height: metric("topBanner") * 0.85) // change the size of banner view
        
        // ******Adding two vertical bar
        self.lineView.frame = CGRect(x: self.view.bounds.width/3 - 1, y: metric("topBanner") * 0.35, width: 1, height: metric("topBanner") * 0.55)
        self.lineViewSec.frame = CGRect(x: self.view.bounds.width/3 * 2 - 1, y: metric("topBanner") * 0.35, width: 1, height: metric("topBanner") * 0.55)
        self.lineView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.8)
        self.lineViewSec.backgroundColor = UIColor.lightGray.withAlphaComponent(0.8)
        
        self.view.addSubview(lineView)
        self.view.addSubview(lineViewSec)
        self.view.sendSubview(toBack: lineView)
        self.view.sendSubview(toBack: lineViewSec)
        
        // **********
        
        let newOrigin = CGPoint(x: 0, y: self.view.bounds.height - self.forwardingView.bounds.height)
        self.forwardingView.frame.origin = newOrigin
    }
    
    override func loadView() {
        super.loadView()
        
        if let aBanner = self.createBanner() {
            aBanner.isHidden = true
            self.view.insertSubview(aBanner, belowSubview: self.forwardingView)
            self.bannerView = aBanner
        }
    }
    
    // *******Control the lineView hidden or not
    func bannerButnOnePressed() {
        self.lineView.isHidden = true
    }
    
    func bannerButnOneUp() {
        self.lineView.isHidden = false
    }
    
    func bannerButnTwoPressed() {
        self.lineView.isHidden = true
        self.lineViewSec.isHidden = true
    }
    
    func bannerButnTwoUp() {
        self.lineView.isHidden = false
        self.lineViewSec.isHidden = false
    }
    
    func bannerButnThreePressed() {
        self.lineViewSec.isHidden = true
    }
    
    func bannerButnThreeUp() {
        self.lineViewSec.isHidden = false
    }
    
    // *********end
    
    override func viewWillAppear(_ animated: Bool) {
        self.bannerView?.isHidden = false
        self.keyboardHeight = self.heightForOrientation(self.interfaceOrientation, withTopBanner: true)
    }
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        self.forwardingView.resetTrackedViews()
        self.shiftStartingState = nil
        self.shiftWasMultitapped = false
        
        // optimization: ensures smooth animation
        if let keyPool = self.layout?.keyPool {
            for view in keyPool {
                view.shouldRasterize = true
            }
        }
        
        self.keyboardHeight = self.heightForOrientation(toInterfaceOrientation, withTopBanner: true)
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        // optimization: ensures quick mode and shift transitions
        if let keyPool = self.layout?.keyPool {
            for view in keyPool {
                view.shouldRasterize = false
            }
        }
    }
    
    func heightForOrientation(_ orientation: UIInterfaceOrientation, withTopBanner: Bool) -> CGFloat {
        let isPad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
        
        //TODO: hardcoded stuff
        let actualScreenWidth = (UIScreen.main.nativeBounds.size.width / UIScreen.main.nativeScale)
        let canonicalPortraitHeight = (isPad ? CGFloat(264) : CGFloat(orientation.isPortrait && actualScreenWidth >= 400 ? 226 : 216))
        let canonicalLandscapeHeight = (isPad ? CGFloat(264) : CGFloat(162))
        let topBannerHeight = (withTopBanner ? metric("topBanner") : 0)
        
        return CGFloat(orientation.isPortrait ? canonicalPortraitHeight + topBannerHeight : canonicalLandscapeHeight + topBannerHeight)
    }
    
    /*
    BUG NOTE

    None of the UIContentContainer methods are called for this controller.
    */
    
    //override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
    //    super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    //}
    
    func setupKeys() {
        if self.layout == nil {
            return
        }
        
        for page in keyboard.pages {
            for rowKeys in page.rows { // TODO: quick hack
                for key in rowKeys {
                    if let keyView = self.layout?.viewForKey(key) {
                        keyView.removeTarget(nil, action: nil, for: UIControlEvents.allEvents)
                        
                        switch key.type {
                        case Key.KeyType.keyboardChange:
                            keyView.addTarget(self, action: #selector(KeyboardViewController.advanceTapped(_:)), for: .touchUpInside)
                        case Key.KeyType.backspace:
                            let cancelEvents: UIControlEvents = [UIControlEvents.touchUpInside, UIControlEvents.touchUpInside, UIControlEvents.touchDragExit, UIControlEvents.touchUpOutside, UIControlEvents.touchCancel, UIControlEvents.touchDragOutside]
                            
                            keyView.addTarget(self, action: #selector(KeyboardViewController.backspaceDown(_:)), for: .touchDown)
                            keyView.addTarget(self, action: #selector(KeyboardViewController.backspaceUp(_:)), for: cancelEvents)
                            keyView.addTarget(self, action: #selector(onTouchUpInside(_:forEvent:)), for: .touchUpInside)
                            keyView.addTarget(self, action: #selector(onTouchDown(_:forEvent:)), for: .touchDown)
                        case Key.KeyType.shift:
                            keyView.addTarget(self, action: #selector(KeyboardViewController.shiftDown(_:)), for: .touchDown)
                            keyView.addTarget(self, action: #selector(KeyboardViewController.shiftUp(_:)), for: .touchUpInside)
                            keyView.addTarget(self, action: #selector(KeyboardViewController.shiftDoubleTapped(_:)), for: .touchDownRepeat)
                            keyView.addTarget(self, action: #selector(shiftPressed), for: .touchUpInside)
                        case Key.KeyType.modeChange:
                            keyView.addTarget(self, action: #selector(KeyboardViewController.modeChangeTapped(_:)), for: .touchDown)
                        case Key.KeyType.settings:
                            keyView.addTarget(self, action: #selector(KeyboardViewController.toggleSettings), for: .touchUpInside)
                        default:
                            break
                        }
                        
                        if key.isCharacter {
                            //if UIDevice.current.userInterfaceIdiom != UIUserInterfaceIdiom.pad {
                                keyView.addTarget(self, action: #selector(KeyboardViewController.showPopup(_:)), for: [.touchDown, .touchDragInside, .touchDragEnter])
                                keyView.addTarget(keyView, action: Selector("hidePopup"), for: [.touchDragExit, .touchCancel])
                                keyView.addTarget(self, action: #selector(KeyboardViewController.hidePopupDelay(_:)), for: [.touchUpInside, .touchUpOutside, .touchDragOutside])
                            //}
                        }
                        
                        if key.hasOutput {
                            keyView.addTarget(self, action: #selector(KeyboardViewController.keyPressedHelper(_:)), for: .touchUpInside)
                            if key.secondaryOutput != nil {
                                keyView.addTarget(self, action: "keyDown:", for: .touchDown)
                                keyView.addTarget(self, action: #selector(KeyboardViewController.cancelSecondaryTextTimer), for: [.touchUpInside, .touchUpOutside, .touchDragOutside, .touchDragExit, .touchCancel])
                            }
                            keyView.addTarget(self, action: #selector(onTouchUpInside(_:forEvent:)), for: .touchUpInside)
                            keyView.addTarget(self, action: #selector(onTouchDown(_:forEvent:)), for: .touchDown)

                        }
                        
                        if key.type != Key.KeyType.shift && key.type != Key.KeyType.modeChange {
                            keyView.addTarget(self, action: #selector(KeyboardViewController.highlightKey(_:)), for: [.touchDown, .touchDragInside, .touchDragEnter])
                            keyView.addTarget(self, action: #selector(KeyboardViewController.unHighlightKey(_:)), for: [.touchUpInside, .touchUpOutside, .touchDragOutside, .touchDragExit, .touchCancel])
                        }
                        
                        keyView.addTarget(self, action: #selector(KeyboardViewController.playKeySound), for: .touchDown)
                    }
                }
            }
        }
    }
    
    // Issue #1: https://github.com/BiAffect/iOSKeyboard/issues/1
    // TODO: change callback directly into the action of addTarget method
    @objc func onTouchUpInside(_ sender: KeyboardKey, forEvent event: UIEvent!) {
            keyloggerAdapter.onTouchUpInside(sender, layout: layout, forEvent: event)
    }
    @objc func onTouchDown(_ sender: KeyboardKey, forEvent event: UIEvent!) {
            keyloggerAdapter.onTouchDown(sender, forEvent: event);
    }
    
    /////////////////
    // POPUP DELAY //
    /////////////////
    
    var keyWithDelayedPopup: KeyboardKey?
    var popupDelayTimer: Timer?
    
    @objc func showPopup(_ sender: KeyboardKey) {
        if sender == self.keyWithDelayedPopup {
            self.popupDelayTimer?.invalidate()
        }
        sender.showPopup()
    }
    
    @objc func hidePopupDelay(_ sender: KeyboardKey) {
        self.popupDelayTimer?.invalidate()
        
        if sender != self.keyWithDelayedPopup {
            self.keyWithDelayedPopup?.hidePopup()
            self.keyWithDelayedPopup = sender
        }
        
        if sender.popup != nil {
            self.popupDelayTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(KeyboardViewController.hidePopupCallback), userInfo: nil, repeats: false)
        }
    }
    
    @objc func hidePopupCallback() {
        self.keyWithDelayedPopup?.hidePopup()
        self.keyWithDelayedPopup = nil
        self.popupDelayTimer = nil
    }
    
    /////////////////////
    // POPUP DELAY END //
    /////////////////////
    
    override func didReceiveMemoryWarning() {
        print("MEMORY WARNING")
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated
    }

    // TODO: this is currently not working as intended; only called when selection changed -- iOS bug
    override func textDidChange(_ textInput: UITextInput?) {
        self.contextChanged()
    }
    
    func contextChanged() {
        self.setCapsIfNeeded()
        self.autoPeriodState = .noSpace
    }
    
    func setHeight(_ height: CGFloat) {
        if self.heightConstraint == nil {
            self.heightConstraint = NSLayoutConstraint(
                item:self.view,
                attribute:NSLayoutAttribute.height,
                relatedBy:NSLayoutRelation.equal,
                toItem:nil,
                attribute:NSLayoutAttribute.notAnAttribute,
                multiplier:0,
                constant:height)
            self.heightConstraint!.priority = UILayoutPriority(rawValue: 1000)
            
            self.view.addConstraint(self.heightConstraint!) // TODO: what if view already has constraint added?
        }
        else {
            self.heightConstraint?.constant = height
        }
    }
    
    func updateAppearances(_ appearanceIsDark: Bool) {
        self.layout?.solidColorMode = self.solidColorMode()
        self.layout?.darkMode = appearanceIsDark
        self.layout?.updateKeyAppearance()
      debugPrint(self.darkMode())
        self.bannerView?.darkMode = appearanceIsDark
        self.settingsView?.darkMode = appearanceIsDark
        //Fix for iOS12 update bugs where touches on the forwarding view are not being handled properly
        //Fix just updates the background color of the forwarding view to blend in with the keyboard background view, 
        //so that it can respond to touches
        if #available(iOSApplicationExtension 10.0, *){
            if(!appearanceIsDark){
                self.forwardingView?.backgroundColor = UIColor(displayP3Red: (203/255), green: (206/255), blue: (226/255), alpha: 0.1)
            }else{
                self.forwardingView?.backgroundColor = UIColor(displayP3Red: (42/255), green: (43/255), blue: (53/255), alpha: 0.1)
            }

        } else {
            // Fallback on earlier versions
        }
    }
    
    @objc func highlightKey(_ sender: KeyboardKey) {
        sender.isHighlighted = true
    }
    
    @objc func unHighlightKey(_ sender: KeyboardKey) {
        sender.isHighlighted = false
    }
    
    @objc func keyPressedHelper(_ sender: KeyboardKey) {
        if let model = self.layout?.keyForView(sender) {
            self.keyPressed(model, secondaryMode: self.secondaryTextMode)

            // auto exit from special char subkeyboard
            if model.type == Key.KeyType.space || model.type == Key.KeyType.return {
                self.currentMode = 0
            }
            else if model.lowercaseOutput == "'" {
                self.currentMode = 0
            }
            else if model.type == Key.KeyType.character {
                self.currentMode = 0
            }
            
            // auto period on double space
            // TODO: timeout
            
            self.handleAutoPeriod(model)
            // TODO: reset context
        }
        
        self.setCapsIfNeeded()
    }
    
    func handleAutoPeriod(_ key: Key) {
        if !UserDefaults.standard.bool(forKey: kPeriodShortcut) {
            return
        }
        
        if self.autoPeriodState == .firstSpace {
            if key.type != Key.KeyType.space {
                self.autoPeriodState = .noSpace
                return
            }
            
            let charactersAreInCorrectState = { () -> Bool in
                let previousContext = self.textDocumentProxy.documentContextBeforeInput
                
                if previousContext == nil || (previousContext!).characters.count < 3 {
                    return false
                }
                
                var index = previousContext!.endIndex
                
                index = (previousContext?.index(before: index))!
                if previousContext![index] != " " {
                    return false
                }
                
                index = (previousContext?.index(before: index))!
                if previousContext![index] != " " {
                    return false
                }
                
                index = (previousContext?.index(before: index))!
                let char = previousContext![index]
                if self.characterIsWhitespace(char) || self.characterIsPunctuation(char) || char == "," {
                    return false
                }
                
                return true
            }()
            
            if charactersAreInCorrectState {
                self.textDocumentProxy.deleteBackward()
                self.textDocumentProxy.deleteBackward()
                self.textDocumentProxy.insertText(".")
                self.textDocumentProxy.insertText(" ")
            }
            
            self.autoPeriodState = .noSpace
        }
        else {
            if key.type == Key.KeyType.space {
                self.autoPeriodState = .firstSpace
            }
        }
    }
    
    func cancelBackspaceTimers() {
        self.backspaceDelayTimer?.invalidate()
        self.backspaceRepeatTimer?.invalidate()
        self.backspaceDelayTimer = nil
        self.backspaceRepeatTimer = nil
    }
    
    @objc func backspaceDown(_ sender: KeyboardKey) {
        self.cancelBackspaceTimers()
        self.keyPressed(Key(.backspace), secondaryMode: false)
        self.setCapsIfNeeded()
        
        // trigger for subsequent deletes
        self.backspaceDelayTimer = Timer.scheduledTimer(timeInterval: backspaceDelay - backspaceRepeat, target: self, selector: #selector(KeyboardViewController.backspaceDelayCallback), userInfo: nil, repeats: false)
    }
    
    @objc func backspaceUp(_ sender: KeyboardKey) {
        self.cancelBackspaceTimers()
        updateButtons()
    }
    
    @objc func backspaceDelayCallback() {
        self.backspaceDelayTimer = nil
        self.backspaceRepeatTimer = Timer.scheduledTimer(timeInterval: backspaceRepeat, target: self, selector: #selector(KeyboardViewController.backspaceRepeatCallback), userInfo: nil, repeats: true)
    }
    
    @objc func backspaceRepeatCallback() {
        self.playKeySound()
        self.keyPressed(Key(.backspace), secondaryMode: true)
        //self.textDocumentProxy.deleteBackward()
        self.setCapsIfNeeded()
    }
    
    @objc func cancelSecondaryTextTimer() {
        self.secondaryTextMode = false
        self.secondaryTextTimer?.invalidate()
        self.secondaryTextTimer = nil
    }
    
    @objc func shiftDown(_ sender: KeyboardKey) {
        self.shiftStartingState = self.shiftState
        
        if let shiftStartingState = self.shiftStartingState {
            if shiftStartingState.uppercase() {
                // handled by shiftUp
                return
            }
            else {
                switch self.shiftState {
                case .disabled:
                    self.shiftState = .enabled
                case .enabled:
                    self.shiftState = .disabled
                case .locked:
                    self.shiftState = .disabled
                }
                
                (sender.shape as? ShiftShape)?.withLock = false
            }
        }
        self.updateButtons()
    }
    
    @objc func shiftUp(_ sender: KeyboardKey) {
        if self.shiftWasMultitapped {
            // do nothing
        }
        else {
            if let shiftStartingState = self.shiftStartingState {
                if !shiftStartingState.uppercase() {
                    // handled by shiftDown
                }
                else {
                    switch self.shiftState {
                    case .disabled:
                        self.shiftState = .enabled
                    case .enabled:
                        self.shiftState = .disabled
                    case .locked:
                        self.shiftState = .disabled
                    }
                    
                    (sender.shape as? ShiftShape)?.withLock = false
                }
            }
        }

        self.shiftStartingState = nil
        self.shiftWasMultitapped = false
        self.updateButtons()
    }
    
    @objc func shiftDoubleTapped(_ sender: KeyboardKey) {
        self.shiftWasMultitapped = true
        
        switch self.shiftState {
        case .disabled:
            self.shiftState = .locked
        case .enabled:
            self.shiftState = .locked
        case .locked:
            self.shiftState = .disabled
        }
    }
    
    func updateKeyCaps(_ uppercase: Bool) {
        let characterUppercase = (UserDefaults.standard.bool(forKey: kSmallLowercase) ? uppercase : true)
        self.layout?.updateKeyCaps(false, uppercase: uppercase, characterUppercase: characterUppercase, shiftState: self.shiftState)
    }
    
    @objc func modeChangeTapped(_ sender: KeyboardKey) {
        if let toMode = self.layout?.viewToModel[sender]?.toMode {
            self.currentMode = toMode
        }
    }
    
    func setMode(_ mode: Int) {
        self.forwardingView.resetTrackedViews()
        self.shiftStartingState = nil
        self.shiftWasMultitapped = false
        
        let uppercase = self.shiftState.uppercase()
        let characterUppercase = (UserDefaults.standard.bool(forKey: kSmallLowercase) ? uppercase : true)
        self.layout?.layoutKeys(mode, uppercase: uppercase, characterUppercase: characterUppercase, shiftState: self.shiftState)
        
        self.setupKeys()
    }
    
    @objc func advanceTapped(_ sender: KeyboardKey) {
        self.forwardingView.resetTrackedViews()
        self.shiftStartingState = nil
        self.shiftWasMultitapped = false
        
        self.advanceToNextInputMode()
    }
    
    @IBAction func toggleSettings() {
        // lazy load settings
        if self.settingsView == nil {
            if let aSettings = self.createSettings() {
                aSettings.darkMode = self.darkMode()
                
                aSettings.isHidden = true
                self.view.addSubview(aSettings)
                self.settingsView = aSettings
                
                aSettings.translatesAutoresizingMaskIntoConstraints = false
                
                let widthConstraint = NSLayoutConstraint(item: aSettings, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.width, multiplier: 1, constant: 0)
                let heightConstraint = NSLayoutConstraint(item: aSettings, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.height, multiplier: 1, constant: 0)
                let centerXConstraint = NSLayoutConstraint(item: aSettings, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0)
                let centerYConstraint = NSLayoutConstraint(item: aSettings, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0)
                
                self.view.addConstraint(widthConstraint)
                self.view.addConstraint(heightConstraint)
                self.view.addConstraint(centerXConstraint)
                self.view.addConstraint(centerYConstraint)
            }
        }
        
        
        
        if let settings = self.settingsView {
            let hidden = settings.isHidden
            settings.isHidden = !hidden
            self.forwardingView.isHidden = hidden
            self.forwardingView.isUserInteractionEnabled = !hidden
            self.bannerView?.isHidden = hidden
        }
    }
    
    /*
    @IBAction func toggleProfile() {
        // lazy load settings
        if self.profileView == nil {
            if let aProfiles = self.createProfile() {
                aProfiles.darkMode = self.darkMode()
                
                aProfiles.isHidden = true
                self.view.addSubview(aProfiles)
                self.profileView = aProfiles
                
                aProfiles.translatesAutoresizingMaskIntoConstraints = false
                
                let widthConstraint = NSLayoutConstraint(item: aProfiles, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.width, multiplier: 1, constant: 0)
                let heightConstraint = NSLayoutConstraint(item: aProfiles, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.height, multiplier: 1, constant: 0)
                let centerXConstraint = NSLayoutConstraint(item: aProfiles, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0)
                let centerYConstraint = NSLayoutConstraint(item: aProfiles, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0)
                
                self.view.addConstraint(widthConstraint)
                self.view.addConstraint(heightConstraint)
                self.view.addConstraint(centerXConstraint)
                self.view.addConstraint(centerYConstraint)
            }
        }
        
        
        
        if let profile = self.profileView {
            let hidden = profile.isHidden
            profile.isHidden = !hidden
            //self.editProfilesView?.isHidden = hidden
            //self.editProfilesView?.isUserInteractionEnabled = !hidden
        }
    }
    */
    
    func setCapsIfNeeded() -> Bool {
        if self.shouldAutoCapitalize() {
            switch self.shiftState {
            case .disabled:
                self.shiftState = .enabled
            case .enabled:
                self.shiftState = .enabled
            case .locked:
                self.shiftState = .locked
            }
            
            return true
        }
        else {
            switch self.shiftState {
            case .disabled:
                self.shiftState = .disabled
            case .enabled:
                self.shiftState = .disabled
            case .locked:
                self.shiftState = .locked
            }
            
            return false
        }
    }
    
    func characterIsPunctuation(_ character: Character) -> Bool {
        return (character == ".") || (character == "!") || (character == "?")
    }
    
    func characterIsNewline(_ character: Character) -> Bool {
        return (character == "\n") || (character == "\r")
    }
    
    func characterIsWhitespace(_ character: Character) -> Bool {
        // there are others, but who cares
        return (character == " ") || (character == "\n") || (character == "\r") || (character == "\t")
    }
    
    func stringIsWhitespace(_ string: String?) -> Bool {
        if string != nil {
            for char in (string!).characters {
                if !characterIsWhitespace(char) {
                    return false
                }
            }
        }
        return true
    }
    
    func shouldAutoCapitalize() -> Bool {
        if !UserDefaults.standard.bool(forKey: kAutoCapitalization) {
            return false
        }
        
        let traits = self.textDocumentProxy
        if let autocapitalization = traits.autocapitalizationType {
            let documentProxy = self.textDocumentProxy
            //var beforeContext = documentProxy.documentContextBeforeInput
            
            switch autocapitalization {
            case .none:
                return false
            case .words:
                if let beforeContext = documentProxy.documentContextBeforeInput {
                    let previousCharacter = beforeContext[beforeContext.characters.index(before: beforeContext.endIndex)]
                    return self.characterIsWhitespace(previousCharacter)
                }
                else {
                    return true
                }
            
            case .sentences:
                if let beforeContext = documentProxy.documentContextBeforeInput {
                    let offset = min(3, beforeContext.characters.count)
                    var index = beforeContext.endIndex
                    
                    for i in 0 ..< offset {
                        index = beforeContext.index(before: index)
                        let char = beforeContext[index]
                        
                        if characterIsPunctuation(char) {
                            if i == 0 {
                                return false //not enough spaces after punctuation
                            }
                            else {
                                return true //punctuation with at least one space after it
                            }
                        }
                        else {
                            if !characterIsWhitespace(char) {
                                return false //hit a foreign character before getting to 3 spaces
                            }
                            else if characterIsNewline(char) {
                                return true //hit start of line
                            }
                        }
                    }
                    
                    return true //either got 3 spaces or hit start of line
                }
                else {
                    return true
                }
            case .allCharacters:
                return true
            }
        }
        else {
            return false
        }
    }
    
    // this only works if full access is enabled
    @objc func playKeySound() {
        if !UserDefaults.standard.bool(forKey: kKeyboardClicks) {
            return
        }
        
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(execute: {
            AudioServicesPlaySystemSound(1104)
        })
    }
    
    func playSecondaryKeySound() {
        if !UserDefaults.standard.bool(forKey: kKeyboardClicks) {
            return
        }
        
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(execute: {
            AudioServicesPlaySystemSound(1103)
        })
    }
    
    //////////////////////////////////////
    // MOST COMMONLY EXTENDABLE METHODS //
    //////////////////////////////////////
    
    class var layoutClass: KeyboardLayout.Type { get { return KeyboardLayout.self }}
    class var layoutConstants: LayoutConstants.Type { get { return LayoutConstants.self }}
    class var globalColors: GlobalColors.Type { get { return GlobalColors.self }}
    
    func keyPressed(_ key: Key, secondaryMode: Bool) {
        self.textDocumentProxy.insertText(key.outputForCase(self.shiftState.uppercase(), secondary: secondaryMode))
    }
    
    func updateButtons() {
        return
    }
    
    @objc func shiftPressed() {
        return 
    }
    
    // a banner that sits in the empty space on top of the keyboard
    func createBanner() -> ExtraView? {
        // note that dark mode is not yet valid here, so we just put false for clarity
        //return ExtraView(globalColors: self.dynamicType.globalColors, darkMode: false, solidColorMode: self.solidColorMode())
        return nil
    }
    
    // a settings view that replaces the keyboard when the settings button is pressed
    func createSettings() -> ExtraView? {
        // note that dark mode is not yet valid here, so we just put false for clarity
        let settingsView = DefaultSettings(globalColors: type(of: self).globalColors, darkMode: false, solidColorMode: self.solidColorMode())
        settingsView.backButton?.addTarget(self, action: #selector(KeyboardViewController.toggleSettings), for: UIControlEvents.touchUpInside)
        settingsView.tableView?.reloadData()
        return settingsView
    }
    
    /*
    func createProfile() -> ExtraView? {
        // note that dark mode is not yet valid here, so we just put false for clarity
        let profileView = Profiles(globalColors: type(of: self).globalColors, darkMode: false, solidColorMode: self.solidColorMode())
        
        profileView.backButton?.addTarget(self, action: #selector(KeyboardViewController.toggleProfile), for: UIControlEvents.touchUpInside)
        profileView.callBack = printHere
        return profileView
    }*/
    
    // MARK: SBBAuthManagerDelegateProtocol methods
    
    private let kSessionTokenKey = "sessionToken"
    private let kUsernamePropertyKey = "username"
    private let kPasswordPropertyKey = "password"
    
    private let kKeychainService = "edu.uic.psychiatry.biaffect"
    private let kKeychainAccessGroup = "UPV4CB4H6W.edu.uic.psychiatry.biaffect"

    private var sessionToken: String? {
        get {
            return getKeychainObject(kSessionTokenKey) as? String
        }
        set (newValue) {
            setKeychainObject(newValue as NSSecureCoding?, key: kSessionTokenKey)
        }
    }

    private var email: String? {
        get {
            return getKeychainObject(kUsernamePropertyKey) as? String
        }
        set (newValue) {
            setKeychainObject(newValue as NSSecureCoding?, key: kUsernamePropertyKey)
        }
    }

    public var password: String? {
        get {
            return getKeychainObject(kPasswordPropertyKey) as? String
        }
        set (newValue) {
            setKeychainObject(newValue as NSSecureCoding?, key: kPasswordPropertyKey)
        }
    }

    public func sessionToken(forAuthManager authManager: SBBAuthManagerProtocol) -> String? {
        let token = self.sessionToken
        #if DEBUG
            print("getting Session Token: \(String(describing: token))")
        #endif
        return token
    }
    
    public func authManager(_ authManager: SBBAuthManagerProtocol?, didGetSessionToken sessionToken: String?, forEmail email: String?, andPassword password: String?) {
        #if DEBUG
            print("setting Session Token: \(String(describing: sessionToken))")
        #endif
        self.sessionToken = sessionToken
        self.email = email
        self.password = password
    }
    
    public func email(forAuthManager authManager: SBBAuthManagerProtocol?) -> String? {
        return self.email
    }
    
    public func password(forAuthManager authManager: SBBAuthManagerProtocol?) -> String? {
        return self.password
    }
    
    // store & retrieve values from the same keychain used by BridgeAppSDK in BiAffect app
    private let lockQueue = DispatchQueue(label: "org.sagebase.UserLockQueue")
    
    private var keychain: SBAKeychainWrapper {
        return SBAKeychainWrapper(service: kKeychainService, accessGroup: kKeychainAccessGroup)
    }

    private func getKeychainObject(_ key: String) -> NSSecureCoding? {
        var obj: NSSecureCoding?
        lockQueue.sync {
            obj = self._getKeychainObject_NoLock(key)
        }
        return obj
    }
    
    private func _getKeychainObject_NoLock(_ key: String) -> NSSecureCoding? {
        var err: NSError?
        let obj: NSSecureCoding? = keychain.object(forKey: key, error: &err)
        if let error = err {
            print("Error accessing keychain \(key): \(error.code) \(error)")
        }
        return obj
    }
    
    private func setKeychainObject(_ object: NSSecureCoding?, key: String) {
        lockQueue.async {
            self._setKeychainObject_NoLock(object, key: key)
        }
    }
    
    private func _setKeychainObject_NoLock(_ object: NSSecureCoding?, key: String) {
        do {
            if let obj = object {
                try keychain.setObject(obj, forKey: key)
            }
            else {
                try keychain.removeObject(forKey: key)
            }
        }
        catch let error as NSError {
            print("Failed to set \(key): \(error.code) \(error.localizedDescription)")
        }
    }

}
