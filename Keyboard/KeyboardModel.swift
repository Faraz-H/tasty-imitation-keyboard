//
//  KeyboardModel.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/10/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//
import Foundation

var counter = 0

enum ShiftState {
    case disabled
    case enabled
    case locked
    
    func uppercase() -> Bool {
        switch self {
        case .disabled:
            return false
        case .enabled:
            return true
        case .locked:
            return true
        }
    }
}

class Keyboard {
    var pages: [Page]
    
    init() {
        self.pages = []
    }
    
    func add(key: Key, row: Int, page: Int) {
        if self.pages.count <= page {
            for _ in self.pages.count...page {
                self.pages.append(Page())
            }
        }
        
        self.pages[page].add(key: key, row: row)
    }
}

class Page {
    var rows: [[Key]]
    
    init() {
        self.rows = []
    }
    
    func add(key: Key, row: Int) {
        if self.rows.count <= row {
            for _ in self.rows.count...row {
                self.rows.append([])
            }
        }
        
        self.rows[row].append(key)
    }
    
    func maxRowSize()->Double {
        var currentMax:Double = 0
        for row in 0..<self.rows.count {
            currentMax = max(currentMax, getRowSize(rowNum: row))
        }
        return currentMax
    }
    
    func getRowSize(rowNum: Int) -> Double {
        let row = self.rows[rowNum]
        var sum: Double = 0
        for key in row {
            if let keysize = key.size {
                sum += keysize
            }
            
        }
        return sum
    }
    
    func setRelativeSizes(percentArray: [Double], rowNum: Int) {
        assert(self.rows.count > rowNum)
        let sum = percentArray.reduce(0, +)
        assert(sum < 1.01 && sum > 0.99)
        assert(percentArray.count == self.rows[rowNum].count)
        let maxSize = self.maxRowSize()
        for i in 0..<percentArray.count {
            self.rows[rowNum][i].size = percentArray[i] * maxSize
        }
    }
    
}

class Key: Hashable {
    enum KeyType {
        case character
        case specialCharacter
        case shift
        case backspace
        case tab
        case modeChange
        case keyboardChange
        case period
        case space
        case `return`
        case settings
        case other
    }
    
    var type: KeyType
    var uppercaseKeyCap: String?
    var lowercaseKeyCap: String?
    var uppercaseOutput: String?
    var lowercaseOutput: String?
    var secondaryOutput: String?
    var toMode: Int? //if the key is a mode button, this indicates which page it links to
    var size: Double? //relative size of key compared to the others
    
    var isCharacter: Bool {
        get {
            switch self.type {
            case
            .character,
            .specialCharacter,
            .period:
                return true
            default:
                return false
            }
        }
    }
    
    var isSpecial: Bool {
        get {
            switch self.type {
            case .shift:
                return true
            case .backspace:
                return true
            case .modeChange:
                return true
            case .keyboardChange:
                return true
            case .return:
                return true
            case .settings:
                return true
            default:
                return false
            }
        }
    }
    
    var hasOutput: Bool {
        get {
            return (self.uppercaseOutput != nil) || (self.lowercaseOutput != nil)
        }
    }
    
    // TODO: this is kind of a hack
    var hashValue: Int
    
    init(_ type: KeyType) {
        self.type = type
        self.hashValue = counter
        self.size = 1
        counter += 1
    }
    
    convenience init(_ key: Key) {
        self.init(key.type)
        
        self.uppercaseKeyCap = key.uppercaseKeyCap
        self.lowercaseKeyCap = key.lowercaseKeyCap
        self.uppercaseOutput = key.uppercaseOutput
        self.lowercaseOutput = key.lowercaseOutput
        self.toMode = key.toMode
        self.size = 1
    }
    
    func setLetter(_ letter: String) {
        self.lowercaseOutput = (letter as NSString).lowercased
        self.uppercaseOutput = (letter as NSString).uppercased
        self.lowercaseKeyCap = self.lowercaseOutput
        self.uppercaseKeyCap = self.uppercaseOutput
    }
    
    func setLetter(_ letter: String, secondaryLetter: String) {
        self.lowercaseOutput = (letter as NSString).lowercased
        self.uppercaseOutput = (letter as NSString).uppercased
        self.lowercaseKeyCap = self.lowercaseOutput
        self.uppercaseKeyCap = self.uppercaseOutput
        self.secondaryOutput = secondaryLetter
    }
    
    func outputForCase(_ uppercase: Bool, secondary: Bool) -> String {
        // leaving unwrapped optionals here bc within null checks, ain't broke, don't fix.
        if secondary && (self.secondaryOutput != nil){
            return self.secondaryOutput!
        } else if uppercase {
            if self.uppercaseOutput != nil {
                return self.uppercaseOutput!
            } else if self.lowercaseOutput != nil {
                return self.lowercaseOutput!
            } else {
                return ""
            }
        }
        else {
            if self.lowercaseOutput != nil {
                return self.lowercaseOutput!
            } else if self.uppercaseOutput != nil {
                return self.uppercaseOutput!
            } else {
                return ""
            }
        }
    }
    
    func keyCapForCase(_ uppercase: Bool) -> String {
        // leaving unwrapped optionals here bc within null checks, ain't broke, don't fix.
        if uppercase {
            if self.uppercaseKeyCap != nil {
                return self.uppercaseKeyCap!
            } else if self.lowercaseKeyCap != nil {
                return self.lowercaseKeyCap!
            } else {
                return ""
            }
        }
        else {
            if self.lowercaseKeyCap != nil {
                return self.lowercaseKeyCap!
            } else if self.uppercaseKeyCap != nil {
                return self.uppercaseKeyCap!
            } else {
                return ""
            }
        }
    }
}

func ==(lhs: Key, rhs: Key) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

