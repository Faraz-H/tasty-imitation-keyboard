//
//  ExNumKeyboard.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/10/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

func exNumKeyboard() -> Keyboard {
    let exNumKeyboard = Keyboard()
    
    let shift = Key(.shift)
    let backspace = Key(.backspace)
    let offset = 0

    for key in [":~", "Q1", "W2", "E3", "R4", "T5", "Y6", "U7", "I8", "O9", "P0", "({", ")}", "/\\"] {
        let keyModel = Key(.character)
        if key.characters.count == 1 {
            keyModel.setLetter(key)
        }
        else {
            let secondLetterIndex = key.index(key.startIndex, offsetBy: 1)
            keyModel.setLetter(String(key[key.startIndex]), secondaryLetter: String(key[secondLetterIndex]))
        }
        exNumKeyboard.add(key: Key(keyModel), row: 0 + offset, page: 0)
    }

    let tabKey = Key(.tab)
    tabKey.uppercaseKeyCap = "tab"
    tabKey.uppercaseOutput = "\t"
    tabKey.lowercaseOutput = "\t"
    tabKey.size = 1
    exNumKeyboard.add(key: Key(tabKey), row: 1 + offset, page: 0)
    for key in ["A#", "S$", "D%", "F+", "G-", "H=", "J*", "K^", "L&", "!¡", "\"<", "'>"] {
        let keyModel = Key(.character)
        if key.characters.count == 1 {
            keyModel.setLetter(key)
        }
        else {
            let secondLetterIndex = key.index(key.startIndex, offsetBy: 1)
            keyModel.setLetter(String(key[key.startIndex]), secondaryLetter: String(key[secondLetterIndex]))
        }
        exNumKeyboard.add(key: Key(keyModel), row: 1 + offset, page: 0)
    }
    let tab2 = Key(.tab)
    tab2.uppercaseKeyCap = "tab"
    tab2.uppercaseOutput = "\t"
    tab2.lowercaseOutput = "\t"
    //exNumKeyboard.add(key: Key(tab2, row: 1 + offset, page: 0)
    
    
    exNumKeyboard.add(key: Key(shift), row: 2 + offset, page: 0)
    
    for key in ["Z`", "X_", "C✓", "V°", "B×", "N≈", "M÷", ",;", ".•", "?¿"] {
        let keyModel = Key(.character)
        if key.characters.count == 1 {
            keyModel.setLetter(key)
        }
        else {
            let secondLetterIndex = key.index(key.startIndex, offsetBy: 1)
            keyModel.setLetter(String(key[key.startIndex]), secondaryLetter: String(key[secondLetterIndex]))
        }
        exNumKeyboard.add(key: Key(keyModel), row: 2 + offset, page: 0)
    }
    
    //let backspace = Key(.backspace)
    exNumKeyboard.add(key: Key(backspace), row: 2 + offset, page: 0)
    let keyModeChangeNumbers = Key(.modeChange)
    keyModeChangeNumbers.uppercaseKeyCap = "123"
    keyModeChangeNumbers.toMode = 1
    exNumKeyboard.add(key: Key(keyModeChangeNumbers), row: 3 + offset, page: 0)
    
    
    
    let keyboardChange = Key(.keyboardChange)
    exNumKeyboard.add(key: Key(keyboardChange), row: 3 + offset, page: 0)
    
    //let settings = Key(.settings)
    //exNumKeyboard.add(key: Key(settings, row: 3 + offset, page: 0)
    
    let space = Key(.space)
    space.uppercaseKeyCap = "space"
    space.uppercaseOutput = " "
    space.lowercaseOutput = " "
    exNumKeyboard.add(key: Key(space), row: 3 + offset, page: 0)
    
    let keyModel = Key(.specialCharacter)
    keyModel.setLetter("@")
    exNumKeyboard.add(key: Key(keyModel), row: 3 + offset, page: 0)
    
    let returnKey = Key(.return)
    returnKey.uppercaseKeyCap = "return"
    returnKey.uppercaseOutput = "\n"
    returnKey.lowercaseOutput = "\n"
    exNumKeyboard.add(key: Key(returnKey), row: 3 + offset, page: 0)
    
    let atSize = 1 / exNumKeyboard.pages[0].maxRowSize()
    let spaceBarSize = 0.6 - atSize
    
    exNumKeyboard.pages[0].setRelativeSizes(percentArray: [0.1, 0.1, spaceBarSize, atSize, 0.2], rowNum: 3 + offset)
    
    for key in ["#", "$", "&", ":", "-", "7", "8", "9", "/", "°"] {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(key)
        exNumKeyboard.add(key: Key(keyModel), row: 0, page: 1)
    }
    
    for key in ["@", "(", ")", "=", "+", "4", "5", "6", "*", "_"] {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(key)
        exNumKeyboard.add(key: Key(keyModel), row: 1, page: 1)
    }
    
    let keyModeChangeSpecialCharacters = Key(.modeChange)
    keyModeChangeSpecialCharacters.uppercaseKeyCap = "#+="
    keyModeChangeSpecialCharacters.toMode = 2
    exNumKeyboard.add(key: Key(keyModeChangeSpecialCharacters), row: 2, page: 1)
    
    for key in ["'", "\"", "%", "1", "2", "3"] {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(key)
        exNumKeyboard.add(key: Key(keyModel), row: 2, page: 1)
    }
    
    exNumKeyboard.add(key: Key(backspace), row: 2, page: 1)
    
    let keyModeChangeLetters = Key(.modeChange)
    keyModeChangeLetters.uppercaseKeyCap = "ABC"
    keyModeChangeLetters.toMode = 0
    exNumKeyboard.add(key: Key(keyModeChangeLetters), row: 3, page: 1)
    
    exNumKeyboard.add(key: Key(keyboardChange), row: 3, page: 1)
    
    //exNumKeyboard.add(key: Key(settings), row: 3, page: 1)
    
    exNumKeyboard.add(key: Key(space), row: 3, page: 1)
    
    for key in [",", "0", "."] {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(key)
        exNumKeyboard.add(key: Key(keyModel), row: 3, page: 1)
    }
    
    exNumKeyboard.add(key: Key(returnKey), row: 3, page: 1)
    exNumKeyboard.pages[1].setRelativeSizes(percentArray: [0.1, 0.1, 0.3, 0.1, 0.1, 0.1, 0.2], rowNum: 3 + offset)
    
    for key in ["£", "€", "¥", "₵", "©", "®", "™", "~", "¿", "≈"] {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(key)
        exNumKeyboard.add(key: Key(keyModel), row: 0, page: 2)
    }
    
    for key in ["[", "]", "{", "}", "<", ">", "^", "¡", "×", "•"] {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(key)
        exNumKeyboard.add(key: Key(keyModel), row: 1, page: 2)
    }
    
    exNumKeyboard.add(key: Key(keyModeChangeNumbers), row: 2, page: 2)
    
    for key in ["`", ";", "÷", "\\", "|", "✓"] {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(key)
        exNumKeyboard.add(key: Key(keyModel), row: 2, page: 2)
    }
    
    exNumKeyboard.add(key: Key(backspace), row: 2, page: 2)
    
    exNumKeyboard.add(key: Key(keyModeChangeLetters), row: 3, page: 2)
    
    exNumKeyboard.add(key: Key(keyboardChange), row: 3, page: 2)
    
    //exNumKeyboard.add(key: Key(settings), row: 3, page: 2)
    
    exNumKeyboard.add(key: Key(space), row: 3, page: 2)
    
    exNumKeyboard.add(key: Key(returnKey), row: 3, page: 2)
    exNumKeyboard.pages[2].setRelativeSizes(percentArray: [0.1, 0.1, 0.6, 0.2], rowNum: 3 + offset)
    
    return exNumKeyboard
}

func proportionalButtonSize(page: Page, percentage: Double)->Double {
    assert(percentage < 1)
    let maxRowSize = page.maxRowSize()
    return maxRowSize * percentage
}
