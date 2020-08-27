//
//  ExtraView.swift
//  TastyImitationKeyboard
//
//  Created by Alexei Baboulevitch on 10/5/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import UIKit

class ExtraView: UIView {
    
    var globalColors: GlobalColors.Type?
    var darkMode: Bool
    var solidColorMode: Bool

    
    
    //added outputFunc
    required init(globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool) {
        self.globalColors = globalColors
        self.darkMode = darkMode
        self.solidColorMode = solidColorMode
        super.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.globalColors = nil
        self.darkMode = false
        self.solidColorMode = false
        super.init(coder: aDecoder)
    }
    
    func updateAppearance()
    {print("Updating")}
    
     func getMaxY()->CGFloat {
        return self.frame.maxY
    }
    
    func getMinY()->CGFloat {
        return self.frame.minY
    }
    
    func getMidY()->CGFloat {
        return self.frame.midY
    }
    
    func getMaxX()->CGFloat {
        return self.frame.maxX
    }
    
    func getMinX()->CGFloat {
        return self.frame.minX
    }
    
    func getMidX()->CGFloat {
        return self.frame.midX
    }
}



