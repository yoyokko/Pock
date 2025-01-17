//
//  CCBrightnessUpItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 16/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import Defaults

class CCBrightnessUpItem: ControlCenterItem {
    
    override var enabled: Bool{ return Defaults[.shouldShowBrightnessItem] && Defaults[.shouldShowBrightnessUpItem] }
    
    private let key: KeySender = KeySender(keyCode: NX_KEYTYPE_BRIGHTNESS_UP, isAux: true)
    
    override var title: String  { return "brightness-up" }
    
    override var icon:  NSImage { return NSImage(named: title)!.resize(w: 30, h: 30) }
    
    override func action() -> Any? {
        key.send()
        return DKBrightness.getBrightnessLevel()
    }
    
    override func longPressAction() {
        parentWidget?.showSlideableController(for: self, currentValue: DKBrightness.getBrightnessLevel())
    }
    
    override func didSlide(at value: Double) {
        DKBrightness.setBrightnessLevel(level: Float(value))
        DK_OSDUIHelper.showHUD(type: .brightness, filled: CUnsignedInt(DKBrightness.getBrightnessLevel() * 16))
    }
    
}
