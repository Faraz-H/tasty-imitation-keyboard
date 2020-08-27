//
//  KeyboardAdapter.swift
//  BiAffectKeyboard
//
//  Created by Andrea Piscitello on 16/10/16.
//  Copyright © 2016 Apple. All rights reserved.
//

import Foundation
import UIKit
import Keylogger
import BridgeSDK

class KeyboardSessionController: SessionController {
    override public func sessionEnd() {
        // get the session before calling super, which nils it out
        let session = self.activeSession
        super.sessionEnd()
        
        let archive = SBBDataArchive(reference: "KeyboardSession", jsonValidationMapping: nil)
        archive.usesV1LegacySchema = true
        archive.setArchiveInfoObject(NSNumber(value: 2), forKey: "schemaRevision")
        guard let data = session?.toJsonData() else { return }
        archive.insertData(intoArchive: data, filename: "Session.json", createdOn: session!.timestamp)
        do {
            try archive.complete()
        } catch let error {
            print("Error completing archive before encrypting: \(error)")
        }
        archive.encryptAndUploadArchive()
    }
}

extension Session {
    func toJsonData() -> Data? {
        let jsonKeylogs = self.keylogs.map({ $0.toJson() })
        let jsonAccelerations = self.accelerations.map({ $0.toJson() })
        let jsonSession : [String: Any] = [
            "timestamp": self.timestamp.timeIntervalSince1970,
            "duration": self.duration,
            "keylogs": jsonKeylogs,
            "accelerations": jsonAccelerations
        ]
        let data = try? JSONSerialization.data(withJSONObject: jsonSession, options: [])
        return data
    }
}

extension Keylog {
    func toJson() -> [String: Any] {
        var json = [String: Any]()
        json["timestamp"] = self.timestamp.timeIntervalSince1970
        json["value"] = self.value
        json["duration"] = self.duration
        json["distanceFromPrevious"] = self.distanceFromPrevious
        json["distanceFromCenter"] = self.distanceFromCenter
        if let force = self.force {
            let forceJson : [String: Any] = [
                "value": force.value,
                "max": force.max
            ]
            json["force"] = forceJson
        }
        if let radius = self.radius {
            let radiusJson: [String: Any] = [
                "value": radius.value,
                "tolerance": radius.tolerance
            ]
            json["radius"] = radiusJson
        }
        
        return json
    }
}

extension Acceleration {
    func toJson() -> [String: Any] {
        var json = [String: Any]()
        json["x"] = self.x
        json["y"] = self.y
        json["z"] = self.z
        return json
    }
}

internal class KeyloggerAdapter {
    public static let sharedInstance = KeyloggerAdapter()
    
    private let sessionController = KeyboardSessionController()
    
    // FIXME: Issue #2 https://github.com/BiAffect/iOSKeyboard/issues/2
    private var touchMap = [UITouch:Double]()
    private var timer : Timer?
    
    public func onTouchUpInside(_ sender: KeyboardKey, layout: KeyboardLayout?, forEvent event: UIEvent?) {
        guard let touchEvents = event?.allTouches else {
            return
        }
        guard let layout = layout else {
            return
        }
        
        let key = layout.keyForView(sender)?.type
        let keylog : Keylog
        
        if(key == Key.KeyType.backspace) {
            keylog = Keylog(value: Keylog.KeyType.Backspace )
        }
        else if(key == Key.KeyType.space || key == Key.KeyType.keyboardChange) {
            keylog = Keylog(value: Keylog.KeyType.Alphanum)
        }
        else {
            keylog = Keylog(key: sender.text)
        }
        
        
        for touch in touchEvents {
            guard touchMap[touch] != nil else {
                continue
            }
            guard touch.phase == UITouchPhase.ended else {
                if(touch.phase == UITouchPhase.cancelled) {
                    touchMap.removeValue(forKey: touch)
                }
                continue
            }
            
            // Global Coordinates
            keylog.coordinates = touch.location(in: sender.window)
            
            // Relative Distance
            let touchPoint = CGPoint(x: touch.location(in: sender).x, y: touch.location(in: sender).y)
            let keyCenter = Utils.getCenter(sender.frame.size)
            keylog.distanceFromCenter = Utils.distance(touchPoint, b: keyCenter)
            
            // FIXME: Radius
            if touch.majorRadius > 0 {
                let value = Double(touch.majorRadius)
                let tolerance = Double(touch.majorRadiusTolerance)
                keylog.radius = Keylog.Radius(value: value, tolerance: tolerance)
            }
            
            // Duration
            if let touchDownTime = touchMap[touch] {
                keylog.duration = touch.timestamp - touchDownTime
                touchMap.removeValue(forKey: touch)
            }
            
            // Force
            if #available(iOS 9.0, *) {
                if touch.force > 0 {
                    let value = Double(touch.force)
                    let max = Double(touch.maximumPossibleForce)
                    keylog.force = Keylog.Force(value: value, max: max)
                }
            }
        }
        
        sessionController.addKeylog(keylog)
        clearTouchMap()
    }
    
    public func onTouchDown(_ sender:KeyboardKey, forEvent event: UIEvent?) {
        guard let touchEvents = event?.allTouches else {
            return
        }
        
        for touch in touchEvents {
            if(touch.phase == UITouchPhase.began && touchMap[touch] == nil) {
                touchMap[touch] = touch.timestamp
            }
        }
        clearTouchMap()
    }
    
    public func addSuggestion() {
        sessionController.addSuggestion()
    }
    
    public func addAutocorrection() {
        sessionController.addAutocorrection()
    }
    
    // FIXME: Issue #2 https://github.com/BiAffect/iOSKeyboard/issues/2
    private func clearTouchMap() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: Session.Timeout, target: self, selector: #selector(removeEndedTouches), userInfo: nil, repeats: false)
        removeEndedTouches()
    }

    @objc private func removeEndedTouches() {
        for key in touchMap.keys {
            if(key.phase == UITouchPhase.ended || key.phase == UITouchPhase.cancelled) {
                touchMap.removeValue(forKey: key)
            }
        }
    }
}
