//
//  KeySenderHelper.h
//  Pock
//
//  Created by Pierluigi Galdi on 04/05/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

#ifndef KeySenderHelper_h
#define KeySenderHelper_h

#include <stdio.h>
#include <CoreGraphics/CoreGraphics.h>

void KeySenderPress(uint16_t keyCode, _Bool isAux);
void KeySenderRelease(uint16_t keyCode, _Bool isAux);

void KeyboardShortcutSenderPress(CGKeyCode keyCode, _Bool cmd, _Bool alt, _Bool ctrl, _Bool shift);

#endif /* KeySenderHelper_h */
