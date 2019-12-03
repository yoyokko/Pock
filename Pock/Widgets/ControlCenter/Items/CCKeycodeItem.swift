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
        if icon != nil && icon!.count > 0 {
            let d = NSData(base64Encoded: icon ?? "", options: NSData.Base64DecodingOptions.ignoreUnknownCharacters);
            iconImage = NSImage(data: d! as Data)?.resize(w: 25, h: 25, color: NSColor.clear)
        } else {
            iconImage = nil;
        }
        
        if conditionApp != nil {
            _activeApp = conditionApp ?? "";
            _enabled = false;
        } else {
            _enabled = true;
            _activeApp = ""
        }

        super.init(parentWidget: parentWidget)
    }

    override var enabled: Bool { return _enabled }
    override var activeApp: String { return _activeApp }
    private var key: KeyboardShortcutSender
    private var keyCodeName: String
    private var iconImage: NSImage?
    private var _activeApp: String
    private var _enabled: Bool

    override var title: String  { return self.keyCodeName }
    
    override var icon:  NSImage? { return iconImage }
    
    override func action() -> Any? {
        key.send()
//        NSWorkspace.shared.notificationCenter.post(name: .shouldReloadControlCenterWidget, object: nil)
        return ""
    }
    
    override func longPressAction() {
    }
}
