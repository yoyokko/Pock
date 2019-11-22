//
//  CCKeycodeItem.swift
//  Pock
//
//  Created by Edward Chen on 2019/11/21.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import Defaults

class CCKeyCode: ControlCenterItem {
    
    init(parentWidget: ControlCenterWidget?, keyCode: CGKeyCode, cmd: Bool, alt: Bool, ctrl: Bool, shift: Bool, title: String, icon: String?, conditionApp: String? = nil) {
        key = KeyboardShortcutSender(keyCode: keyCode, cmd: cmd, alt: alt, ctrl: ctrl, shift: shift)
        keyCodeName = title
        if icon != nil {
            let d = NSData(base64Encoded: icon ?? "", options: NSData.Base64DecodingOptions.ignoreUnknownCharacters);
            iconImage = NSImage(data: d as! Data)?.resize(w: 25, h: 25, color: NSColor.clear)
        } else {
            iconImage = nil;
        }
        
        if (conditionApp != nil) {
            isActive = false;
            activeApp = conditionApp!;
            if NSWorkspace.shared.frontmostApplication?.localizedName == activeApp {
                isActive = true;
            }
        } else {
            isActive = true;
            activeApp = "";
        }
        
        super.init(parentWidget: parentWidget)
        
        if activeApp != "" {
            observation = NSWorkspace.shared.observe(\.frontmostApplication, options: [.initial, .new, .old]) { [weak self] object, change in
//                print(object, change)
                self?.frontmostApplicationDidChange()
            }
//            NotificationCenter.default.addObserver(self, selector:#selector(checkActiveApp), name: NSWorkspace.didActivateApplicationNotification, object: nil)
        }
    }

    override var enabled: Bool{ return isActive }
    
    private var key: KeyboardShortcutSender
    private var keyCodeName: String
    private var iconImage: NSImage?
    private var isActive: Bool
    private var activeApp: String
    private var observation: NSKeyValueObservation?
    
    override var title: String  { return self.keyCodeName }
    
    override var icon:  NSImage? { return iconImage }
    
    override func action() -> Any? {
        key.send()
        NSWorkspace.shared.notificationCenter.post(name: .shouldReloadControlCenterWidget, object: nil)
        return ""
    }
    
    override func longPressAction() {
    }
    
    func frontmostApplicationDidChange() {
        print("frontmostApplicationDidChange", NSWorkspace.shared.frontmostApplication?.localizedName)
        
        if NSWorkspace.shared.frontmostApplication?.localizedName == activeApp {
            isActive = true;
            print("Active by ", activeApp, " refresh")
        } else {
            isActive = false;
        }
        
        NSWorkspace.shared.notificationCenter.post(name: .shouldReloadControlCenterWidget, object: nil)
    }
    
    @objc func checkActiveApp(noti: Notification) {
        print(noti)
        if NSWorkspace.shared.frontmostApplication?.localizedName == activeApp {
            isActive = true;
        } else {
            isActive = false;
        }
//        let activeAppName = noti.userInfo?[NSWorkspace.applicationUserInfoKey] as! String;
//        if activeAppName == activeApp {
//            self.isActive = true;
//        } else {
//            self.isActive = false;
//        }
    }
}
