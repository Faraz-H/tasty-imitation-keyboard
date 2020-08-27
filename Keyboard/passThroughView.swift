//
//  passThroughView.swift
//  TastyImitationKeyboard
//
//  Created by Benjamin Katz on 11/6/16.
//  Copyright © 2016 Apple. All rights reserved.
//

import Foundation
import UIKit

class PassThroughView: UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews {
            if !subview.isHidden && subview.alpha > 0 && subview.isUserInteractionEnabled && subview.point(inside: convert(point, to: subview), with: event) {
                return true
            }
        }
        return false
    }
}
