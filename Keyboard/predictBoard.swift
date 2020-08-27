//
//  predictboard.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 9/24/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//
import UIKit
import SQLite
/*
 This is the demo keyboard. If you're implementing your own keyboard, simply follow the example here and then
 set the name of your KeyboardViewController subclass in the Info.plist file.
 */


// temp parse thing :: START
extension String {
    var html2AttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return nil }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch let error as NSError {
            print(error.localizedDescription)
            return  nil
        }
    }
    var html2String: String {
        return html2AttributedString?.string ?? ""
    }
}

extension Dictionary where Value: Comparable {
    var valueKeySorted: [(Key, Value)] {
        return sorted{ if $0.value != $1.value { return $0.value > $1.value } else { return String(describing: $0.key) < String(describing: $1.key) } }
    }
}

// temp parse thing :: END


class PredictBoard: KeyboardViewController, UIPopoverPresentationControllerDelegate {
    
    var banner: PredictboardBanner? = nil
//    var recommendationEngine: Database? = nil
    var reccommendationEngineLoaded = false
    var editProfilesView: ExtraView?
//    var profileView: Profiles?
//    var phrasesView: Phrases?
    var total = 100
    let globalQueue = DispatchQueue.global(qos: .userInitiated)
    var keyPressTimer: Timer?
    var canPress: Bool = true
    let canPressDelay: TimeInterval = 0.15
    var deleteScreen:DeleteViewController?
    let defaultProf = "Default"
    var alreadyUpdating : Bool = false
    var autoCompleted : Bool = false
    var dePunked : Bool = false
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        UserDefaults.standard.register(defaults: ["profile": self.defaultProf])
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        keyPressTimer?.invalidate()
    }
    
    override func keyPressed(_ key: Key, secondaryMode: Bool) {
        
        var keyOutput = ""
        if key.type != .backspace {
            keyOutput = key.outputForCase(self.shiftState.uppercase(), secondary: secondaryMode)
        }
        
        if key.type == .shift {
            //updateButtons()
            return
        }
        
        self.canPress = false
        self.keyPressTimer = Timer.scheduledTimer(timeInterval: canPressDelay, target: self, selector: #selector(resetCanPress), userInfo: nil, repeats: false)
        
        if key.type == .backspace {
            if fastDeleteMode(key: key, secondaryMode: secondaryMode) {
                fastDelete()
                return //in fast delete mode do not update buttons
            } else {
                backspace()
            }
        }
        
        if key.type == .return && !UserDefaults.standard.bool(forKey: "keyboardInputToApp") {
            self.banner?.saveButton.sendActions(for: .touchUpInside)
            return
        }
        
        let punctuation = [".", ",", ";", "!", "?", "\'", ":", "-"]
        if key.type == .space {
            let components = self.contextBeforeInput().components(separatedBy: " ")
            let lastWord = components[components.count-1]
            
            if let correction = self.corrections(lastWord)?.first {
                if !dePunked { // Going to override what is there, but don't want to do that in case of a dePunk correction
                    self.completeCorrection(correction, lastCharacter: " ")
                } else { // if dePunked, then just continue on without overriding typed text
                    self.addText(text: keyOutput)
                }
            } else {
                self.addText(text: keyOutput)
            }
            if self.isAutocorrectEnabled() && self.reccommendationEngineLoaded {
                self.incrementNgrams()
            }
            dePunked = false
        } else if punctuation.contains(keyOutput) {
            let components = self.contextBeforeInput().components(separatedBy: " ")
            let lastWord = components[components.count-1]
            
            /* Remove space if last word was auto completed and user has entered punctuation */
            if (self.autoCompleted && components[components.count-2] != lastWord) {
                backspace()
            }
            
            if let correction = self.corrections(lastWord)?.first {
                self.completeCorrection(correction, lastCharacter: keyOutput)
            } else {
                self.addText(text: keyOutput)
            }
        } else {
            self.addText(text: keyOutput)
        }
        //self.updateButtons()
        self.autoCompleted = false
    }
    
    // First component is the user entered text - need to elliminate anything prior to punctuation, as well as the punctuation itself
    func processFirstComponent(_ firstComponent: String) -> String {
        var updatedFirstComponent = firstComponent
        let charset: Set<Character> = [".", ",", ";", "!", "?", ":", "\"", "-"] // Not using "\'" - which interferes with contractionated words
        // Iterate through the punctuations and indicate the highest index of them, then use that as the index to start with when cutting out the substring
        var highestIndex = 0
        for punk in charset {
            var highestPunkIndexNum = 0
            if let index = firstComponent.index(of: punk) {
                highestPunkIndexNum = firstComponent.distance(from: firstComponent.startIndex, to: index)
            }
            highestIndex = highestPunkIndexNum > highestIndex ? highestPunkIndexNum : highestIndex
        }
        
        // Use highest index to cut out the substring with just the last bit of text
        if highestIndex > 0 {
            let indexStartOfRealSuggestionStart = firstComponent.index(firstComponent.startIndex, offsetBy: highestIndex+1)
            
            // then pull out substring from the index after the last punctuation to the end and turn it into the final string.  Account for case where it is empty.
            updatedFirstComponent = String(firstComponent[indexStartOfRealSuggestionStart...])
            dePunked = true // dePunked signifies that the text had the punctuation and everything before it taken out
        }
        return updatedFirstComponent
    }
    
    func isAutocorrectEnabled() -> Bool {
        return self.textDocumentProxy.keyboardType == UIKeyboardType.default ||
            self.textDocumentProxy.keyboardType == UIKeyboardType.asciiCapable
    }
    
    func backspace() {
        if UserDefaults.standard.bool(forKey: "keyboardInputToApp") {
            self.textDocumentProxy.deleteBackward()
        }
        else {
            self.bannerTextBackspace()
        }
    }
    
    func addText(text:String) {
        if UserDefaults.standard.bool(forKey: "keyboardInputToApp") {
            self.textDocumentProxy.insertText(text)
        }
        else {
            self.banner?.textField.text? += text
        }
    }
    
    func contextBeforeInput() -> String {
        var context = ""
        if UserDefaults.standard.bool(forKey: "keyboardInputToApp") {
            if let textContext = self.textDocumentProxy.documentContextBeforeInput {
                context = textContext
            }
        }
        else {
            context = (self.banner?.textField.text) ?? "<unknown>"
        }
        return context
    }
    
    func contextAfterInput() ->String {
        var context = ""
        if UserDefaults.standard.bool(forKey: "keyboardInputToApp") {
            if let textContext = self.textDocumentProxy.documentContextAfterInput {
                context = textContext
            }
        }
        else {
            context = ""
        }
        return context
    }
    
    func bannerTextBackspace() {
        let oldText = (self.banner?.textField.text) ?? ""
        if oldText.characters.count > 0 {
            let endIndex = oldText.endIndex
            self.banner?.textField.text? = oldText.substring(to: oldText.index(before: endIndex))
            if self.banner?.textField.text?.characters.count == 0 {
            }
        }
    }
    
    override func setupKeys() {
        super.setupKeys()
    }
    
    override func createBanner() -> ExtraView? {
        self.banner = PredictboardBanner(setCaps: self.setCapsIfNeeded, globalColors: type(of: self).globalColors, darkMode: self.darkMode(), solidColorMode: self.solidColorMode())
        
        self.layout?.darkMode
        if let bannerUnwrapped = self.banner {
            bannerUnwrapped.isHidden = true
            //set up profile selector
            bannerUnwrapped.profileSelector.addTarget(self, action: #selector(showPopover), for: .touchUpInside)
            if let userDefProfile = UserDefaults.standard.string(forKey: "profile") {
                bannerUnwrapped.profileSelector.setTitle(userDefProfile, for: UIControlState())
            }
            
            bannerUnwrapped.phraseSelector.addTarget(self, action: #selector(switchToPhraseMode), for: .touchUpInside)
            
            //setup autocomplete buttons
            for button in (bannerUnwrapped.buttons) {
                button.addTarget(self, action: #selector(autocompleteClicked), for: .touchUpInside)
                
            }
            
            //setup autocomplete buttons in in app text input mode
            for button in (bannerUnwrapped.tiButtons) {
                button.addTarget(self, action: #selector(autocompleteClicked), for: .touchUpInside)
            }
        }
        
        self.globalQueue.async {
            // Background thread
            if let bannerunwrapped = self.banner {
//                self.recommendationEngine = Database(progressView: (bannerunwrapped.progressBar), numElements: 30000)
                
                self.reccommendationEngineLoaded = true
                DispatchQueue.main.async {
                    // UI Updates
                    bannerunwrapped.showLoadingScreen(toShow: false)
                    self.updateButtons()
                }
            }
        }
        return self.banner
    }
    
    @objc func resetCanPress() {
        self.canPress = true
    }
    
    func completeCorrection(_ word: String, lastCharacter: String) -> () {
        var word = word
        if(lastCharacter != " ") {
            word.append(lastCharacter)
        }
        if self.isAutocorrectEnabled() && !["\'", "\""].contains(lastCharacter){
            self.autoComplete(word)
            KeyloggerAdapter.sharedInstance.addAutocorrection()
        }
        else {
            self.addText(text: lastCharacter)
        }
    }
    
    func completeSuggestion(_ word:String) -> () {
        self.autoComplete(word)
        KeyloggerAdapter.sharedInstance.addSuggestion()
    }
    
    ///autocomplete code
    func autoComplete(_ word:String) -> () {
        var insertionWord = word
        if (!dePunked) {
            _ = getLastWord(delete: true)
            let postContext = self.contextAfterInput()
            if postContext.characters.count > 0 {
                let postIndex = postContext.startIndex
                if postContext[postIndex] != " " //add space if next word doesnt begin with space
                {
                    insertionWord = word + " "
                }
            } else { //add space if you are the last added word.
                insertionWord = word + " "
            }
            
        } else {
            insertionWord = " "
        }
        dePunked = false
        addText(text: insertionWord)
    }
    
    
    func fastDelete() {
        let deletedWord = getLastWord(delete: true)
        if (deletedWord.characters.count == 0) {
            let context = self.contextBeforeInput()
            
            if context.characters.count > 0 {
                backspace()
                _ = getLastWord(delete: true)
            }
        }
    }
    
    func getLastWord(delete: Bool) ->String {
        var prevWord = ""
        let context = contextBeforeInput()
        if context.characters.count > 0 {
            var index = context.endIndex
            index = context.index(before: index)
            
            while index > context.startIndex && context[index] != " "
            {
                prevWord.insert(context[index], at: prevWord.startIndex)
                index = context.index(before: index)
                if delete{
                    backspace()
                }
            }
            if index == context.startIndex && context[index] != " "
            {
                prevWord.insert(context[index], at: prevWord.startIndex)
                if delete {
                    backspace()
                }
            }
        }
        return prevWord
    }
    
    @objc func autocompleteClicked(_ sender:UIButton) {
        // make sure no accidental double click
        sender.backgroundColor = UIColor.clear
        if !self.canPress {
            return
        }
        
        self.canPress = false
        self.keyPressTimer = Timer.scheduledTimer(timeInterval: canPressDelay, target: self, selector: #selector(resetCanPress), userInfo: nil, repeats: false)
        
        var almostFinalWordToAdd = ""
        var finalWordToAdd = ""
        if let wordToAdd = sender.titleLabel?.text {
            if wordToAdd.first == "\"" {
                almostFinalWordToAdd = String(wordToAdd.dropFirst())
                if wordToAdd.last == "\"" {
                    finalWordToAdd = String(almostFinalWordToAdd.dropLast())
                }
            } else {
                finalWordToAdd = wordToAdd
            }
        }
        
        if finalWordToAdd != " " {
            self.completeSuggestion(finalWordToAdd)
            self.incrementNgrams()
            //updateButtons()
            setCapsIfNeeded()
        }
        self.autoCompleted = true
    }
    
    
    func incrementNgrams() {
        
        self.globalQueue.sync {
            let context = self.contextBeforeInput()
            let components = self.contextBeforeInput().components(separatedBy: " ")
            let count = (components.count) as Int
            var word1 = ""
            var word2 = ""
            var word3 = ""
            if count >= 4 {
                word1 = (components[count-4]) as String
            }
            if count >= 3 {
                word2 = (components[count-3]) as String
            }
            if count >= 2 {
                word3 = (components[count-2]) as String
            }
            
            // Create possible ngrams
            let one_gram = (gram: word3, n: 1)
            let two_gram = (gram: word2+" "+word3, n: 2)
            let three_gram = (gram: word1+" "+word2+" "+word3, n: 3)
            
            // Insert ngrams into database and increment their frequencies
            for ngram in [one_gram, two_gram, three_gram] {
                self.recommendationEngine?.insertAndIncrement(ngram: ngram.gram, n: ngram.n)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        print("ASDFLHASDFLKHASDLFKHASDLFKH MEMORY WARNING")
    }
    
    override func updateButtons() {
        // Get previous words to give to recommendWords()
        // ------------------------
        guard alreadyUpdating == false else {
            return // Prevent concurrent/threaded re-entry; things tend to go *boom* in that case
        }
        
        alreadyUpdating = true
        self.globalQueue.async {
            if self.reccommendationEngineLoaded {
                var context = self.contextBeforeInput()
                context = context.replacingOccurrences(of: "\n", with: " ")
                let normalInputMode = UserDefaults.standard.bool(forKey: "keyboardInputToApp")
                let components = self.contextBeforeInput().components(separatedBy: " ")
                let count = (components.count) as Int
                var word1 = ""
                var word2 = ""
                var current_input = ""
                if count >= 3 {
                    word1 = (components[count-3]) as String
                }
                if count >= 2 {
                    word2 = (components[count-2]) as String
                }
                if count >= 1 {
                    current_input = (components[count-1]) as String
                }
                // ------------------------
                let recEngine = self.recommendationEngine
                let numResults = (normalInputMode ? (self.banner?.numButtons): 5) ?? 0
                
                // UITextChecker
                var recommendations = [String]()
                
                let corrections = self.corrections(current_input)
                if (corrections != nil) { // leave force unwrap bc of nil check
                    recommendations = corrections!
                }
                
                let textChecker = UITextChecker()
                let misspelledRange = textChecker.rangeOfMisspelledWord(
                    in: current_input, range: NSRange(0..<current_input.utf16.count),
                    startingAt: 0, wrap: false, language: "en_US")
                
                if misspelledRange.location != NSNotFound {
                    if let completions = textChecker.completions(forPartialWordRange: misspelledRange, in: current_input, language: "en_US") {
                        recommendations.append(contentsOf: completions)
                    }
                }
                
                if let recEngineUnwrapped = recEngine {
                    recommendations.append(contentsOf: Array(recEngineUnwrapped.recommendWords(word1: word1, word2: word2,
                                                                                               current_input: current_input,
                                                                                               shift_state: self.shiftState,
                                                                                               numResults:numResults)).sorted())
                }
                
                let words = self.contextBeforeInput().components(separatedBy: " ")
                
                // manipulate the user entered word here:
                if let wordsLast = words.last {
                    if(wordsLast.characters.count > 0) {
                        recommendations = recommendations.filter{$0 == "I" || $0.lowercased() != wordsLast.lowercased()}
                        let userWord = self.processFirstComponent(wordsLast)
                        recommendations.insert("\"" + userWord + "\"", at: 0)
                    }
                }
                
                var index = 0
                DispatchQueue.main.async {
                    var buttons = [BannerButton]()
                    
                    if let bann = self.banner {
                        if normalInputMode {
                            buttons = (bann.buttons)
                        } else {
                            buttons = (bann.tiButtons)
                        }
                    }
                    
                    for button in buttons {
                        button.backgroundColor = UIColor.init(red: CGFloat(198)/CGFloat(255), green: CGFloat(202)/CGFloat(255), blue: CGFloat(208)/CGFloat(255), alpha: 0.05)
                        if index < recommendations.count {
                            
                            if let corr = corrections {
                                if(corr.count > 0 && recommendations[index] == corr[0]) {
                                    button.backgroundColor = UIColor.init(red: CGFloat(198)/CGFloat(255), green: CGFloat(202)/CGFloat(255), blue: CGFloat(208)/CGFloat(255), alpha: 0.05)
                                } else {
                                    button.backgroundColor = UIColor.init(red: CGFloat(198)/CGFloat(255), green: CGFloat(202)/CGFloat(255), blue: CGFloat(208)/CGFloat(255), alpha: 0.05)
                                }
                            } else {
                                button.backgroundColor = UIColor.init(red: CGFloat(198)/CGFloat(255), green: CGFloat(202)/CGFloat(255), blue: CGFloat(208)/CGFloat(255), alpha: 0.05)
                            }
                            button.setTitle(recommendations[index], for: UIControlState())
                            button.addTarget(self, action: #selector(KeyboardViewController.playKeySound), for: .touchDown)
                            button.isEnabled = true
                        }
                        else {
                            button.setTitle(" ", for: UIControlState())
                            button.removeTarget(self, action: #selector(KeyboardViewController.playKeySound), for: .touchDown)
                            button.isEnabled = false
                        }
                        index += 1
                    }
                }
            }
            self.alreadyUpdating = false
        }
    }
    
    //Pop ups
    @IBAction func showPopover(sender: UIButton) {
        
        let maxHeight = self.forwardingView.frame.maxY - sender.frame.maxY
        let popUpViewController = PopUpViewController(selector: sender as UIButton, maxHeight: maxHeight, callBack: updateButtons)
        popUpViewController.modalPresentationStyle = UIModalPresentationStyle.popover
        popUpViewController.editButton.addTarget(self, action: #selector(toggleEditProfiles), for: .touchUpInside)
        
        present(popUpViewController, animated: true, completion: nil)
        
        let popoverPresentationController = popUpViewController.popoverPresentationController
        popoverPresentationController?.sourceView = sender
        let height = Int(sender.frame.height)
        let width = Int(sender.frame.height) / 2
        
        
        popoverPresentationController?.sourceRect = CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: width, height: height))
    }
    
    func switchToAddProfileMode(){
        self.showBanner(toShow: true)
        self.showForwardingView(toShow: true)
        if let editProfilesViewUnwrapped = self.editProfilesView {
            self.showView(viewToShow: editProfilesViewUnwrapped, toShow: false)
        }
        
        if let bann = self.banner {
            bann.selectTextView()
            //self.updateButtons()
            bann.textFieldLabel.text = "Profile Name:"
            bann.saveButton.addTarget(self, action: #selector(saveProfile), for: .touchUpInside)
            bann.backButton.addTarget(self, action: #selector(completedAddProfileMode), for: .touchUpInside)
        }
    }
    
    //go from internal text input mode to forwarding view
    func completedAddProfileMode(){
        
        if let bann = self.banner {
            bann.saveButton.removeTarget(self, action: #selector(saveProfile), for: .touchUpInside)
            bann.backButton.removeTarget(self, action: #selector(completedAddProfileMode), for: .touchUpInside)
            bann.selectDefaultView()
        }
        self.showBanner(toShow: false)
        self.showForwardingView(toShow: false)
        
        if let editProfilesViewUnwrapped = self.editProfilesView {
            self.showView(viewToShow: editProfilesViewUnwrapped, toShow: true)
        }
        
    }
    
    
    //go from internal text input mode to profile view
    func saveProfile() {
        var profileName = ""
        if let bannerText = self.banner?.textField.text {
            profileName = bannerText
        }
        if let recommendationEngineUnwrapped = self.recommendationEngine {
            if !(recommendationEngineUnwrapped.checkProfile(profile_name: profileName)) {
                if let bann = self.banner {
                    bann.showWarningView(title: "Duplicate Profile", message: "Please change your profile name")
                }
                return
            }
        }
        
        if let bannerEmptyTextbox = self.banner?.emptyTextbox() {
            if bannerEmptyTextbox {
                return
            }
        }
        
        self.reccommendationEngineLoaded = false
        
        if let bann = self.banner {
            bann.saveButton.removeTarget(self, action: #selector(saveProfile), for: .touchUpInside)
            bann.backButton.removeTarget(self, action: #selector(completedAddProfileMode), for: .touchUpInside)
            bann.selectDefaultView()
            bann.loadingLabel.text = "Creating new Profile (this may take several minutes)"
            bann.showLoadingScreen(toShow: true)
        }
        
        self.globalQueue.sync {
            // Background thread
            if let recommendationEngineUnwrapped = self.recommendationEngine {
                recommendationEngineUnwrapped.numElements = 30000
                recommendationEngineUnwrapped.addProfile(profile_name: profileName)
                DispatchQueue.main.async {
                    // UI Updates
                    if let bann = self.banner {
                        bann.showLoadingScreen(toShow: false)
                    }
                    self.showForwardingView(toShow: false)
                    self.showBanner(toShow: false)
                    self.profileView = self.createProfile(profileName:profileName)
                    
                    if let profileViewUnwrapped = self.profileView {
                        self.showView(viewToShow: profileViewUnwrapped, toShow: true)
                    }
                    
                    self.reccommendationEngineLoaded = true
                }
            }
        }
    }
    
    func showView(viewToShow: ExtraView, toShow: Bool) {
        if toShow {
            viewToShow.darkMode = self.darkMode()
            viewToShow.isHidden = true
            self.view.addSubview(viewToShow)
            
            viewToShow.translatesAutoresizingMaskIntoConstraints = false
            
            let widthConstraint = NSLayoutConstraint(item: viewToShow, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.width, multiplier: 1, constant: 0)
            let heightConstraint = NSLayoutConstraint(item: viewToShow, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.height, multiplier: 1, constant: 0)
            let centerXConstraint = NSLayoutConstraint(item: viewToShow, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0)
            let centerYConstraint = NSLayoutConstraint(item: viewToShow, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0)
            
            self.view.addConstraint(widthConstraint)
            self.view.addConstraint(heightConstraint)
            self.view.addConstraint(centerXConstraint)
            self.view.addConstraint(centerYConstraint)
        }
        viewToShow.isHidden = !toShow
        viewToShow.isUserInteractionEnabled = toShow
        
    }
    
    func showBanner(toShow: Bool) {
        if let bann = self.banner {
            bann.isHidden = !toShow
            bann.isUserInteractionEnabled = toShow
        }
    }
    
    func showForwardingView(toShow: Bool) {
        self.forwardingView.isHidden = !toShow
        self.forwardingView.isUserInteractionEnabled = toShow
    }
    
    func editProfilesNameView() {
        
        if let profileViewUnwrapped = self.profileView {
            textEntryView(toShow: true, view:profileViewUnwrapped)
        }
        
        if let bann = self.banner {
            bann.textFieldLabel.text = "Edit Name:"
            if let profileViewName = profileView?.profileName {
                bann.textField.text = profileViewName
            }
            bann.saveButton.addTarget(self, action: #selector(updateProfileName), for: .touchUpInside)
            bann.backButton.addTarget(self, action: #selector(exiteditProfilesNameView), for: .touchUpInside)
        }
    }
    
    
    func updateProfileName(){
        var newName = ""
        if let bannerText = self.banner?.textField.text {
            newName = bannerText
        }
        
        if let recommendationEngineUnwrapped = self.recommendationEngine {
            if !(recommendationEngineUnwrapped.checkProfile(profile_name: newName)) {
                if let bann = self.banner {
                    bann.showWarningView(title: "Duplicate Profile", message: "Please change your profile name")
                }
                return
            }
        }
        
        if let bannerEmptyTextbox = self.banner?.emptyTextbox() {
            if bannerEmptyTextbox {
                return
            }
        }
        
        if let profileViewUnwrapped = self.profileView {
            profileViewUnwrapped.NavBar.title = newName
        }
        
        if let profileViewName = profileView?.profileName {
            if let recommendationEngineUnwrapped = self.recommendationEngine {
                recommendationEngineUnwrapped.editProfileName(current_name: profileViewName, new_name: newName)
            }
            if self.profileView != nil {
                self.profileView?.profileName = newName
            }
        }
        exiteditProfilesNameView()
    }
    
    func exiteditProfilesNameView() {
        if let profileViewUnwrapped = self.profileView {
            textEntryView(toShow: false, view: profileViewUnwrapped)
        }
        
        if let bann = self.banner {
            bann.saveButton.removeTarget(self, action: #selector(updateProfileName), for: .touchUpInside)
            bann.backButton.removeTarget(self, action: #selector(exiteditProfilesNameView), for: .touchUpInside)
        }
    }
    
    func addDataSourceView() {
        if let profileViewUnwrapped = self.profileView {
            textEntryView(toShow: true, view: profileViewUnwrapped)
        }
        
        if let bann = self.banner {
            bann.textFieldLabel.text = "Data Source URL:"
            bann.textField.text = ""
            bann.saveButton.addTarget(self, action: #selector(addDataSource), for: .touchUpInside)
            bann.backButton.addTarget(self, action: #selector(exitDataSourceView), for: .touchUpInside)
        }
    }
    
    func exitDataSourceView() {
        if let profileViewUnwrapped = self.profileView {
            textEntryView(toShow: false, view: profileViewUnwrapped)
        }
        
        if let bann = self.banner {
            bann.saveButton.removeTarget(self, action: #selector(addDataSource), for: .touchUpInside)
            bann.backButton.removeTarget(self, action: #selector(exitDataSourceView), for: .touchUpInside)
        }
    }
    
    func addDataSource() {
        //grab url before it is cleared
        var myURLString = ""
        if let bannerText = self.banner?.textField.text {
            myURLString = bannerText
        }
        
        if let bannerEmptyTextbox = self.banner?.emptyTextbox() {
            if bannerEmptyTextbox {
                return
            }
        }
        
        var target_profile:String = ""
        
        // REPLACE THIS WITH THE NAME OF THE PROFILE YOU'RE TARGETING, NOT THE ONE YOU'RE USING
        if let profileViewName = self.profileView?.profileName {
            target_profile = profileViewName
            
            if let recommendationEngineUnwrapped = self.recommendationEngine {
                if !(recommendationEngineUnwrapped.checkDataSource(targetProfile: target_profile, dataSource: myURLString)) {
                    if let bann = self.banner {
                        bann.showWarningView(title: "Duplicate Data Source", message: "This data source has already been added")
                    }
                    return
                }
            }
        }
        
        var HTMLArray = [" "]
        
        //For now data source title and data source name are the same
        
        //show loading screen, and open keyboard while loading
        exitDataSourceView()
        self.goToKeyboard()
        if let bann = self.banner {
            bann.showLoadingScreen(toShow: true)
            bann.progressBar.isHidden = true
            bann.loadingLabelMessage.text = "YooHooo"
        }
        
        //start loading data in another thread
        self.globalQueue.async {
            // temp HTML parse code :: START
            DispatchQueue.main.async {
                if let bann = self.banner {
                    bann.loadingLabelMessage.text = "Accessing URL"
                }
                return
            }
            guard let myURL = URL(string: myURLString) else { // include ! after myURLString for first opt, exclude for second opt
                print("Error: \(myURLString) doesn't seem to be a valid URL")
                
                if let bann = self.banner {
                    bann.showWarningView(title: "Warning", message: "Invalid URL. Please try again.")
                    bann.textField.text = myURLString
                }
                
                //self.banner.showLoadingScreen(toShow: false)
                self.addDataSourceView()
                
                return
            }
            
            DispatchQueue.main.async {
                if let bann = self.banner {
                    bann.loadingLabelMessage.text = "Processing text"
                }
                
                return
            }
            
            do {
                //let myHTMLString = try String(contentsOf: myURL, encoding: .utf8) // select only p
                let myHTMLString = try String(contentsOf: myURL, encoding: .utf8).html2String
                print(myHTMLString)
                var modString = (myHTMLString as NSString).replacingOccurrences(of: "\n", with: "   ")
                modString = modString.lowercased()
                let characterset = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789-' ")
                modString = modString.components(separatedBy: characterset.inverted).joined(separator: " ")
                HTMLArray = modString.components(separatedBy: " ")
            } catch let error {
                print("Error: \(error)")
                
                if let bann = self.banner {
                    bann.showWarningView(title: "Warning", message: "Unable to reach URL. Please try again.")
                    bann.showLoadingScreen(toShow: false)
                    bann.progressBar.isHidden = false
                    bann.textField.text = myURLString
                }
                
                self.addDataSourceView()
                
                return
            }
            
            
            // gen n-grams
            var unigrams = [String: Int]()
            var bigrams = [String: Int]()
            var trigrams = [String: Int]()
            
            var i = 0
            
            
            let len = HTMLArray.count
            print(HTMLArray)
            while(i < len){
                // update unigrams
                let curUnigram = HTMLArray[i]
                if curUnigram == ""{
                    i += 1
                    continue
                }
                if (unigrams[curUnigram] != nil) { // leave forced unwrapped bc of nil check
                    unigrams[curUnigram] = unigrams[curUnigram]! + 1
                } else{
                    unigrams[curUnigram] = 1
                }
                
                // update bigrams
                if i < len - 1{
                    if HTMLArray[i+1]==""{
                        i += 1
                        continue
                    }
                    let curBigram = String(describing: HTMLArray[i]) + " " + String(describing: HTMLArray[i+1])
                    if bigrams[curBigram] != nil { // leave forced unwrapped bc of nil check
                        bigrams[curBigram] = bigrams[curBigram]! + 1
                    } else {
                        bigrams[curBigram] = 1
                    }
                }
                
                // update trigrams
                if i < len - 2{
                    if HTMLArray[i+1]=="" || HTMLArray[i+2]==""{
                        i += 1
                        continue
                    }
                    let curTrigram = String(describing: HTMLArray[i]) + " " + String(describing: HTMLArray[i+1]) + " " + String(describing: HTMLArray[i+2])
                    if trigrams[curTrigram] != nil { // leave forced unwrapped bc of nil check
                        trigrams[curTrigram] = trigrams[curTrigram]! + 1
                    } else {
                        trigrams[curTrigram] = 1
                    }
                }
                
                // increment
                i += 1
            }
            
            /*
             print("\n---Unigrams---\n")
             print(unigrams.valueKeySorted)
             print("\n---Bigrams---\n")
             print(bigrams.valueKeySorted)
             print("\n---Trigrams---\n")
             print(trigrams.valueKeySorted)
             */
            // temp HTML parse code :: END
            // Background thread
            // NEW IDEA:
            //   -get all current ngrams from profile (1 db call)
            //   -put those into a set
            //   -if new ngram is not in the set, append to bulk_insert string
            //   -update frequency
            var source = ""
            if let bannerText = self.banner?.textField.text {
                source = bannerText
            }
            
            if let recommendationEngineUnwrapped = self.recommendationEngine {
                recommendationEngineUnwrapped.addDataSource(target_profile: target_profile, new_data_source: source, new_title: source)
            }
            
            var bulk_insert = "INSERT INTO Containers (profile, ngram, n, dataSource, frequency) VALUES "
            var bulk_update = ""
            var all_updates = [String: Int]()
            
            // -----------------------------------
            // is it possible to do a bulk update?
            // idk but I'm gonna try anyway
            // -----------------------------------
            // ---------------------------------------
            var ngramsSet: Set<String>? = nil
            if let recommendationEngineUnwrapped = self.recommendationEngine {
                ngramsSet = recommendationEngineUnwrapped.getNgramsFromProfile(profile: target_profile)
                
                recommendationEngineUnwrapped.numElements = Int(unigrams.count + bigrams.count + trigrams.count)
            }
            
            /*
             DispatchQueue.main.async {
             self.recommendationEngine.counter = 0
             return
             }*/
            
            for unigram in unigrams {
                //self.recommendationEngine?.insertAndIncrement(ngram: unigram.key, n: 1,
                //                                              new_freq: Float64(unigram.value))
                if ngramsSet != nil && (ngramsSet?.contains(unigram.key)) != nil { // nil check protects forced unwrapped below
                    if !((ngramsSet?.contains(unigram.key))!) {
                        // append to bulk insert
                        bulk_insert.append("(\"\(target_profile)\",\"\(unigram.key)\",1,"
                            + "\"\(source)\",\(unigram.value)), ")
                        ngramsSet?.insert(unigram.key)
                    } else {
                        // update frequency
                        // use bulk_update if that's possible
                        let new_update = "UPDATE Containers SET frequency = frequency + \(unigram.value) WHERE profile = \"\(target_profile)\" AND ngram = \"\(unigram.key)\"; "
                        bulk_update.append(new_update)
                        all_updates[unigram.key] = unigram.value
                    }
                    
                } else {
                    // update frequency
                    // use bulk_update if that's possible
                    let new_update = "UPDATE Containers SET frequency = frequency + \(unigram.value) WHERE profile = \"\(target_profile)\" AND ngram = \"\(unigram.key)\"; "
                    bulk_update.append(new_update)
                    all_updates[unigram.key] = unigram.value
                }
                
                /*DispatchQueue.main.async {
                 self.recommendationEngine?.counter += 1
                 return
                 }*/
            }
            
            for bigram in bigrams {
                //self.recommendationEngine?.insertAndIncrement(ngram: bigram.key, n: 2,
                //                                              new_freq: Float64(bigram.value))
                
                if ngramsSet != nil && (ngramsSet?.contains(bigram.key)) != nil { // nil check protects forced unwrapped below
                    if !(ngramsSet?.contains(bigram.key))! {
                        // append to bulk insert
                        bulk_insert.append("(\"\(target_profile)\",\"\(bigram.key)\",2,"
                            + "\"\(source)\",\(bigram.value)), ")
                        ngramsSet?.insert(bigram.key)
                    } else {
                        // update frequency
                        // use bulk_update if that's possible
                        let new_update = "UPDATE Containers SET frequency = frequency + \(bigram.value) WHERE ngram = \"\(bigram.key)\" AND profile = \"\(target_profile)\"; "
                        bulk_update.append(new_update)
                        all_updates[bigram.key] = bigram.value
                    }
                } else {
                    // update frequency
                    // use bulk_update if that's possible
                    let new_update = "UPDATE Containers SET frequency = frequency + \(bigram.value) WHERE ngram = \"\(bigram.key)\" AND profile = \"\(target_profile)\"; "
                    bulk_update.append(new_update)
                    all_updates[bigram.key] = bigram.value
                }
                /* DispatchQueue.main.async {
                 self.recommendationEngine?.counter += 1
                 return
                 }*/
            }
            
            for trigram in trigrams {
                //self.recommendationEngine?.insertAndIncrement(ngram: trigram.key, n: 3,
                //                                              new_freq: Float64(trigram.value))
                if ngramsSet != nil && (ngramsSet?.contains(trigram.key)) != nil { // nil check protects forced unwrapped below
                    if !(ngramsSet?.contains(trigram.key))! {
                        // append to bulk insert
                        bulk_insert.append("(\"\(target_profile)\",\"\(trigram.key)\",3,"
                            + "\"\(source)\",\(trigram.value)), ")
                        ngramsSet?.insert(trigram.key)
                    } else {
                        // update frequency
                        // use bulk_update if that's possible
                        let new_update = "UPDATE Containers SET frequency = frequency + \(trigram.value) WHERE ngram = \"\(trigram.key)\" AND profile = \"\(target_profile)\"; "
                        bulk_update.append(new_update)
                        all_updates[trigram.key] = trigram.value
                    }
                } else {
                    // update frequency
                    // use bulk_update if that's possible
                    let new_update = "UPDATE Containers SET frequency = frequency + \(trigram.value) WHERE ngram = \"\(trigram.key)\" AND profile = \"\(target_profile)\"; "
                    bulk_update.append(new_update)
                    all_updates[trigram.key] = trigram.value
                }
                
                /* DispatchQueue.main.async {
                 self.recommendationEngine?.counter += 1
                 return
                 }*/
            }
            
            // Run insert and update
            do {
                let db_path = dbObjects.db_path_func()
                let db = try SingletonConnection.sharedInstance.connection("\(db_path)/db.sqlite3")
                
                
                DispatchQueue.main.async {
                    if let bann = self.banner {
                        bann.loadingLabelMessage.text = "Updating words"
                    }
                    
                    return
                }
                _ = try db.run(bulk_update)
                
                DispatchQueue.main.async {
                    if let bann = self.banner {
                        bann.loadingLabelMessage.text = "Adding words"
                    }
                    
                    return
                }
                _ = try db.run(String(bulk_insert.characters.dropLast(2))+";")
                
                DispatchQueue.main.async {
                    if let bann = self.banner {
                        bann.loadingLabelMessage.text = "Load Completed"
                    }
                    
                    return
                }
                
            } catch {
                print("Error: \(error)")
            }
            
            DispatchQueue.main.async {
                // UI Updates
                if let bann = self.banner {
                    bann.showLoadingScreen(toShow: false)
                }
                
                self.showForwardingView(toShow: false)
                self.showBanner(toShow: false)
                if let profileViewUnwrapped = self.profileView {
                    profileViewUnwrapped.reloadData()
                    self.showView(viewToShow: profileViewUnwrapped, toShow: true)
                }
            }
        }
    }
    
    func deleteProfilePressed() {
        if let profileViewName = profileView?.profileName {
            if let profileViewUnwrapped = self.profileView {
                self.deleteScreen = DeleteViewController(view: profileViewUnwrapped as UIView, type: "profile", name: (profileViewName))
            }
        }
        
        if let deleteScreenUnwrapped = deleteScreen {
            deleteScreenUnwrapped.cancelButton.addTarget(self, action: #selector(self.removeDeleteScreen), for: .touchUpInside)
            //self.deleteScreen.deleteButton.tag = (indexPath as NSIndexPath).row
            deleteScreenUnwrapped.deleteButton.addTarget(self, action: #selector(self.deleteProfile), for: .touchUpInside)
        }
        
    }
    
    func deleteProfileHelper(profile:String) {
        if let recommendationEngineUnwrapped = self.recommendationEngine {
            recommendationEngineUnwrapped.deleteProfile(profile_name: profile)
        }
        
        if profile == UserDefaults.standard.string(forKey: "profile") {
            UserDefaults.standard.string(forKey: "profile")
            UserDefaults.standard.register(defaults: ["profile": self.defaultProf])
            if let udStanStringForProf = UserDefaults.standard.string(forKey: "profile") {
                if let bann = self.banner {
                    bann.profileSelector.setTitle(udStanStringForProf, for: UIControlState())
                }
            }
        }
    }
    
    func deleteProfile() {
        if let profileName = profileView?.profileName {
            deleteProfileHelper(profile: profileName)
        }
        profileToEditProfiles()
    }
    
    func removeDeleteScreen() {
        if let deleteScreenUnwrapped = deleteScreen {
            deleteScreenUnwrapped.warningView.removeFromSuperview()
        }
        
        self.deleteScreen = nil
    }
    
    func textEntryView(toShow: Bool, view:ExtraView) {
        if toShow {
            showView(viewToShow: view, toShow: false)
            if let bann = self.banner {
                bann.selectTextView()
            }
            //self.updateButtons()
        }
        else {
            if let bann = self.banner {
                bann.selectDefaultView()
            }
            
            //if you cancel just reopen view.  showView will recreate it, we dont need to do that
            if let profileViewUnwrapped = self.profileView {
                profileViewUnwrapped.isHidden = false
                profileViewUnwrapped.isUserInteractionEnabled = true
            }
            
        }
        //updateButtons()
        showForwardingView(toShow: toShow)
        showBanner(toShow: toShow)
        
    }
    
    @IBAction func toggleEditProfiles() {
        let toShow = self.forwardingView.isHidden
        showForwardingView(toShow: toShow)
        showBanner(toShow: toShow)
        if (!toShow) {
            editProfilesView = createEditProfiles()
        }
        
        if let editProfilesViewUnwrapped = self.editProfilesView {
            self.showView(viewToShow: editProfilesViewUnwrapped, toShow: !toShow)
        }
        
        //        showView(viewToShow: editProfilesView, toShow: !toShow)
        
    }
    
    func openProfile(profileName: String) {
        profileView = createProfile(profileName: profileName)
        if let editProfilesViewUnwrapped = self.editProfilesView {
            self.showView(viewToShow: editProfilesViewUnwrapped, toShow: false)
        }
        
        if let profileViewUnwrapped = self.profileView {
            showView(viewToShow: profileViewUnwrapped, toShow: true)
        }
    }
    
    func profileToEditProfiles() {
        editProfilesView = createEditProfiles()
        
        if let editProfilesViewUnwrapped = self.editProfilesView {
            self.showView(viewToShow: editProfilesViewUnwrapped, toShow: true)
        }
        
        if let profileViewUnwrapped = self.profileView {
            showView(viewToShow: profileViewUnwrapped, toShow: false)
        }
    }
    
    func goToKeyboard() {
        if let editProfilesViewUnwrapped = self.editProfilesView {
            self.showView(viewToShow: editProfilesViewUnwrapped, toShow: false)
        }
        
        if let profileViewUnwrapped = self.profileView {
            showView(viewToShow: profileViewUnwrapped, toShow: false)
        }
        
        if let pView = self.phrasesView {
            showView(viewToShow: pView, toShow: false)
        }
        showForwardingView(toShow: true)
        showBanner(toShow: true)
    }
    
    func switchToPhraseMode() {
        phrasesView = createPhrases()
        if let pView = self.phrasesView {
            showView(viewToShow: pView, toShow: true)
        }
        showForwardingView(toShow: false)
        showBanner(toShow: false)
    }
    
    func addPhraseView() {
        if let pView = self.phrasesView {
            textEntryView(toShow: true, view: pView)
        }
        
        if let bann = self.banner {
            bann.textFieldLabel.text = "Add Phrase:"
            bann.saveButton.addTarget(self, action: #selector(addPhrase), for: .touchUpInside)
            bann.backButton.addTarget(self, action: #selector(exitAddPhraseView), for: .touchUpInside)
        }
        
    }
    
    func exitAddPhraseView() {
        if let pView = self.phrasesView {
            textEntryView(toShow: false, view: pView)
            showView(viewToShow: pView, toShow: true)
        }
        
        if let bann = self.banner {
            bann.saveButton.removeTarget(self, action: #selector(addPhrase), for: .touchUpInside)
            bann.backButton.removeTarget(self, action: #selector(exitAddPhraseView), for: .touchUpInside)
        }
        
    }
    
    func addPhrase() {
        if let bannerText = self.banner?.textField.text {
            if let recommendationEngineUnwrapped = self.recommendationEngine {
                if !recommendationEngineUnwrapped.checkPhrase(phrase: (bannerText)) {
                    if let bann = self.banner {
                        bann.showWarningView(title: "Duplicate Phrase", message: "This phrase already exists")
                    }
                    return
                }
            }
        }
        
        if let bannerEmptyTextbox = self.banner?.emptyTextbox() {
            if bannerEmptyTextbox {
                return
            }
        }
        
        if let bannerText = self.banner?.textField.text {
            if let recommendationEngineUnwrapped = self.recommendationEngine {
                recommendationEngineUnwrapped.addPhrase(phrase: (bannerText))
            }
        }
        
        if let pView = self.phrasesView {
            pView.reloadData()
        }
        
        exitAddPhraseView()
    }
    
    func editPhraseView(phrase:String) {
        if let pView = self.phrasesView {
            textEntryView(toShow: true, view: pView)
            pView.oldEditPhrase = phrase
        }
        
        if let bann = self.banner {
            bann.textFieldLabel.text = "Edit Phrase:"
            bann.textField.text = phrase
            bann.saveButton.addTarget(self, action: #selector(editPhrase), for: .touchUpInside)
            bann.backButton.addTarget(self, action: #selector(exitEditPhraseView), for: .touchUpInside)
        }
        
    }
    
    func editPhrase() {
        var newPhrase = ""
        if let bann = self.banner {
            if let bannerTextFieldtext = bann.textField.text {
                newPhrase = bannerTextFieldtext
            }
            if let bannerEmptyTextbox = self.banner?.emptyTextbox() {
                if bannerEmptyTextbox {
                    return
                }
            }
            
            if let bannerText = bann.textField.text {
                if let recommendationEngineUnwrapped = self.recommendationEngine {
                    if !recommendationEngineUnwrapped.checkPhrase(phrase: (bannerText)) {
                        bann.showWarningView(title: "Duplicate Phrase", message: "This phrase already exists")
                        return
                    }
                }
            }
        }
        
        if let pView = self.phrasesView {
            if let recommendationEngineUnwrapped = self.recommendationEngine {
                recommendationEngineUnwrapped.editPhrase(old_phrase: (pView.oldEditPhrase), new_phrase: newPhrase)
            }
            
            pView.reloadData()
        }
        
        exitAddPhraseView()
    }
    
    func exitEditPhraseView() {
        if let pView = self.phrasesView {
            textEntryView(toShow: false, view: pView)
            showView(viewToShow: pView, toShow: true)
            if let pviewTable = pView.tableView {
                pviewTable.setEditing(false, animated: false)
            }
        }
        
        if let bann = self.banner {
            bann.saveButton.removeTarget(self, action: #selector(editPhrase), for: .touchUpInside)
            bann.backButton.removeTarget(self, action: #selector(exitEditPhraseView), for: .touchUpInside)
        }
        
    }
    
    func createEditProfiles() -> ExtraView? {
        let editProfiles = EditProfiles(globalColors: type(of: self).globalColors, darkMode: false, solidColorMode: self.solidColorMode())
        
        if let editProfKbButton = editProfiles.keyboardButton {
            editProfKbButton.action = #selector(toggleEditProfiles)
            editProfKbButton.target = self
        }
        
        if let editProfAddButton = editProfiles.addButton {
            editProfAddButton.action = #selector(switchToAddProfileMode)
            editProfAddButton.target = self
        }
        
        editProfiles.callBack = openProfileCallback
        editProfiles.deleteCallback = deleteProfileHelper
        
        return editProfiles
    }
    
    func createProfile(profileName:String) -> Profiles? {
        // note that dark mode is not yet valid here, so we just put false for clarity
        let profileView = Profiles(profileName: profileName, globalColors: type(of: self).globalColors, darkMode: false, solidColorMode: self.solidColorMode())
        
        if let profKbButton = profileView.keyboardButton {
            profKbButton.action = #selector(goToKeyboard)
            profKbButton.target = self
        }
        
        if let profProfViewButton = profileView.profileViewButton {
            profProfViewButton.action = #selector(profileToEditProfiles)
        }
        
        if let profKbButton = profileView.keyboardButton {
            profKbButton.target = self
        }
        
        if let profEditName = profileView.editName {
            profEditName.action = #selector(editProfilesNameView)
            profEditName.target = self
        }
        
        if let profAddButton = profileView.addButton {
            profAddButton.action = #selector(addDataSourceView)
            profAddButton.target = self
        }
        
        profileView.deleteButton.action = #selector(deleteProfilePressed)
        profileView.deleteButton.target = self
        
        return profileView
    }
    
    func openProfileCallback(tableTitle:String) {
        //let title = tableTitle.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        openProfile(profileName: tableTitle)
        
        if let profileViewUnwrapped = self.profileView {
            profileViewUnwrapped.NavBar.title = tableTitle
            //we dont want you editing the default profile name
            if title == self.defaultProf {
                profileViewUnwrapped.editName.isEnabled = false
                profileViewUnwrapped.deleteButton.isEnabled = false
            }
            else {
                profileViewUnwrapped.editName.isEnabled = true
                profileViewUnwrapped.deleteButton.isEnabled = true
            }
        }
    }
    
    func createPhrases() -> Phrases? {
        // note that dark mode is not yet valid here, so we just put false for clarity
        let phrasesView = Phrases(onClickCallBack: typePhrase, editCallback: editPhraseView, globalColors: type(of: self).globalColors, darkMode: false, solidColorMode: self.solidColorMode())
        
        if let pViewBack = phrasesView.backButton {
            pViewBack.action = #selector(goToKeyboard)
            pViewBack.target = self
        }
        
        if let pViewAdd = phrasesView.addButton {
            pViewAdd.action = #selector(addPhraseView)
            pViewAdd.target = self
        }
        
        return phrasesView
    }
    
    override func shiftPressed() {
        //updateButtons()
    }
    
    override func setCapsIfNeeded() -> Bool {
        if self.shouldAutoCapitalize() {
            switch self.shiftState {
            case .disabled:
                self.shiftState = .enabled
            case .enabled:
                self.shiftState = .enabled
            case .locked:
                self.shiftState = .locked
            }
            self.updateButtons()
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
            self.updateButtons()
            return false
        }
    }
    
    override func shouldAutoCapitalize() -> Bool {
        if !UserDefaults.standard.bool(forKey: kAutoCapitalization) {
            return false
        }
        
        let traits = self.textDocumentProxy
        let normalInputMode = UserDefaults.standard.bool(forKey: "keyboardInputToApp")
        if let autocapitalization = (normalInputMode ? traits.autocapitalizationType : UITextAutocapitalizationType.sentences) {
            switch autocapitalization {
            case .none:
                return false
            case .words:
                let beforeContext = self.contextBeforeInput()
                if beforeContext.characters.count > 0 {
                    let previousCharacter = beforeContext[beforeContext.characters.index(before: beforeContext.endIndex)]
                    return self.characterIsWhitespace(previousCharacter)
                }
                else {
                    return true
                }
                
            case .sentences:
                let beforeContext = self.contextBeforeInput()
                if beforeContext.characters.count > 0 {
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
    
    func typePhrase(_ sentence: String) {
        print(sentence)
        
        let insertionSentence = sentence + " "
        // update database with insertion word
        addText(text: insertionSentence)
        //updateButtons()
        setCapsIfNeeded()
        self.goToKeyboard()
    }
    
    func fastDeleteMode(key:Key, secondaryMode:Bool) ->Bool {
        return (key.type == .backspace && secondaryMode)
    }
    
    func corrections(_ word: String) -> [String]? {
        if let forcedCorrection = self.specialCorrection(word) {
            return [forcedCorrection]
        }
        
        let textChecker = UITextChecker()
        let misspelledRange = textChecker.rangeOfMisspelledWord(
            in: word, range: NSRange(0..<word.utf16.count),
            startingAt: 0, wrap: false, language: "en_US")
        
        if misspelledRange.location != NSNotFound {
            if let textCheckerGuesses = textChecker.guesses(forWordRange: misspelledRange, in: word, language: "en_US") {
                return textCheckerGuesses as [String]
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func specialCorrection(_ word: String) -> String? {
        if(word == "i") {
            return "I"
        }
        if(word.lowercased() == "im") {
            return "I'm"
        }
        return nil
    }
}

