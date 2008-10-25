/*
 * Copyright 2008 Dominic Cooney.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License. 
 */

#import "LifeEffect.h"


static Key adjacentKeys[][7] = {
  { kKeyLeftCtrl, kKeyPgUp, kKey1, kKeyTab, -1 },  // ~
  { kKeyLeftVendor, kKeyTilde, kKey2, kKeyQ, -1 },  // 1
  { kKeyLeftAlt, kKey1, kKey3, kKeyW, -1 },  // 2
  { kKeyX, kKey2, kKey4, kKeyE, -1 },  // 3
  { kKeyC, kKey3, kKey5, kKeyR, -1 },  // 4
  { kKeyV, kKey4, kKey6, kKeyT, -1 },  // 5
  { kKeyB, kKey5, kKey7, kKeyY, -1 },  // 6
  { kKeyN, kKey6, kKey8, kKeyU, -1 },  // 7
  { kKeyM, kKey7, kKey9, kKeyI, -1 },  // 8
  { kKeyComma, kKey8, kKey0, kKeyO, -1 },  // 9
  { kKeyRightAlt, kKey9, kKeyMinus, kKeyP, -1 },  // 0
  { kKeyRightVendor, kKey0, kKeyEquals, kKeyLeftSquare, -1 },  // -
  { kKeyRightMenu, kKeyMinus, kKeyBackspace, kKeyRightSquare, -1 },  // =
  { kKeyRightCtrl, kKeyEquals, kKeyDelete, kKeyBackslash, -1 },  // Backspace
  // second row
  { kKeyTilde, kKeyPgDn, kKeyQ, kKeyCapsLock, -1 },  // Tab
  { kKey1, kKeyTab, kKeyW, kKeyA, -1 },  // Q
  { kKey2, kKeyQ, kKeyE, kKeyS, -1 },  // W
  { kKey3, kKeyW, kKeyR, kKeyD, -1 },  // E
  { kKey4, kKeyE, kKeyT, kKeyF, -1 },  // R
  { kKey5, kKeyR, kKeyY, kKeyG, -1 },  // T
  { kKey6, kKeyT, kKeyU, kKeyH, -1 },  // Y
  { kKey7, kKeyY, kKeyI, kKeyJ, -1 },  // U
  { kKey8, kKeyU, kKeyO, kKeyK, -1 },  // I
  { kKey9, kKeyI, kKeyP, kKeyL, -1 },  // O
  { kKey0, kKeyO, kKeyLeftSquare, kKeySemicolon, -1 },  // P
  { kKeyMinus, kKeyP, kKeyRightSquare, kKeySingleQuote, -1 },  // LeftSquare
  { kKeyEquals, kKeyLeftSquare, kKeyBackslash, kKeyEnter, -1 },  // RightSquare
  { kKeyBackspace, kKeyRightSquare, kKeyDelete, kKeyEnter, -1 },  // Backslash
  // third row
  { kKeyTab, kKeyEnter, kKeyA, kKeyLeftShift, -1 },  // CapsLock
  { kKeyQ, kKeyCapsLock, kKeyS, kKeyZ, -1 },  // A
  { kKeyW, kKeyA, kKeyD, kKeyX, -1 },  // S
  { kKeyE, kKeyS, kKeyF, kKeyC, -1 },  // D
  { kKeyR, kKeyD, kKeyG, kKeyV, -1 },  // F
  { kKeyT, kKeyF, kKeyH, kKeyB, -1 },  // G
  { kKeyY, kKeyG, kKeyJ, kKeyN, -1 },  // H
  { kKeyU, kKeyH, kKeyK, kKeyM, -1 },  // J
  { kKeyI, kKeyJ, kKeyL, kKeyComma, -1 },  // K
  { kKeyO, kKeyK, kKeySemicolon, kKeyPeriod, -1 },  // L
  { kKeyP, kKeyL, kKeySingleQuote, kKeyForwardSlash, -1 },  // Semicolon
  { kKeyLeftSquare, kKeySemicolon, kKeyEnter, kKeyRightShift, -1 },  // SingleQuote
  // Enter has two keys above
  { kKeyLeftSquare, kKeyBackslash, kKeySingleQuote, kKeyCapsLock, kKeyRightShift, -1 },  // Enter
  // fourth row
  { kKeyCapsLock, kKeyUp, kKeyZ, kKeyLeftCtrl, kKeyLeftVendor, -1 },  // LeftShift
  { kKeyA, kKeyLeftShift, kKeyX, kKeyLeftAlt, -1 },  // Z
  { kKeyS, kKeyZ, kKeyC, -1 },  // X
  { kKeyD, kKeyX, kKeyV, -1 },  // C
  { kKeyF, kKeyC, kKeyB, -1 },  // V
  { kKeyG, kKeyV, kKeyN, -1 },  // B
  { kKeyH, kKeyB, kKeyM, -1 },  // N
  { kKeyJ, kKeyN, kKeyComma, -1 },  // M
  { kKeyK, kKeyM, kKeyPeriod, -1 },  // Comma
  { kKeyL, kKeyComma, kKeyForwardSlash, kKeyRightAlt, -1 },  // Period
  { kKeySemicolon, kKeyPeriod, kKeyRightShift, kKeyRightVendor, -1 },  // ForwardSlash
  { kKeySingleQuote, kKeyEnter, kKeyForwardSlash, kKeyUp, kKeyRightMenu, kKeyRightCtrl, -1 },  // RightShift
  // fifth row
  { kKeyLeftShift, kKeyRight, kKeyLeftVendor, kKeyTilde, -1 },  // LeftCtrl
  { kKeyLeftShift, kKeyLeftCtrl, kKeyLeftAlt, kKey1, -1 },  // LeftVendor
  { kKeyZ, kKeyLeftVendor, kKey2, -1 },  // LeftAlt
  { kKeyPeriod, kKeyRightVendor, kKey0, -1 },  // RightAlt
  { kKeyForwardSlash, kKeyRightAlt, kKeyRightMenu, kKeyMinus, -1 },  // RightVendor
  { kKeyRightShift, kKeyRightVendor, kKeyRightCtrl, kKeyEquals, -1 },  // RightMenu
  { kKeyRightShift, kKeyRightMenu, kKeyLeft, kKeyBackspace, -1 },  // RightCtrl
  // top right control pad
  { kKeyDown, kKeyDelete, kKeyPgUp, kKeyEnd, -1 },  // Home
  { kKeyRight, kKeyHome, kKeyTilde, kKeyPgDn, -1 },  // PgUp
  { kKeyLeft, kKeyBackspace, kKeyBackslash, kKeyHome, kKeyEnd, -1 },  // Delete
  { kKeyHome, kKeyDelete, kKeyPgDn, kKeyUp, -1 },  // End
  { kKeyPgUp, kKeyEnd, kKeyTab, kKeyRight, -1 },  // PgDn
  // arrow keys
  { kKeyDelete, kKeyRightCtrl, kKeyDown, -1 },  // Left
  { kKeyPgDn, kKeyDown, kKeyLeftCtrl, kKeyPgUp, -1 },  // Right
  { kKeyUp, kKeyLeft, kKeyRight, kKeyHome, -1 },  // Down
  { kKeyEnd, kKeyRightShift, kKeyLeftShift, kKeyDown, -1 },  // Up
};


@implementation LifeEffect

+ (NSDictionary *)undoProperties {
  return [NSDictionary dictionaryWithObjectsAndKeys:
      @"Color", @"color",
      @"Key Strokes Create Life", @"keyStrokesCreateLife",
      @"Key Strokes Destroy Life", @"keyStrokesDestroyLife",
      nil];
}

- (id)init {
  self = [super init];
  if (self) {
    [self setName:@"Conway's Life"];
    alive = (BOOL *)calloc(kNumKeys, sizeof(BOOL));
    aliveNext = (BOOL *)calloc(kNumKeys, sizeof(BOOL));
    buffer = [[KeyboardDisplayBuffer alloc] init];
    [self setColor:[NSColor greenColor]];
  }
  return self;
}

- (void)dealloc {
  free(alive);
  free(aliveNext);
  [buffer release];
  [super dealloc];
}

- (id)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    alive = (BOOL *)calloc(kNumKeys, sizeof(BOOL));
    aliveNext = (BOOL *)calloc(kNumKeys, sizeof(BOOL));
    buffer = [[KeyboardDisplayBuffer alloc] init];
    [self setColor:[coder decodeObjectForKey:@"color"]];
    [self setKeyStrokesCreateLife:
        [coder decodeBoolForKey:@"keyStrokesCreateLife"]];
    [self setKeyStrokesDestroyLife:
        [coder decodeBoolForKey:@"keyStrokesDestroyLife"]];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:color forKey:@"color"];
  [coder encodeBool:keyStrokesCreateLife forKey:@"keyStrokesCreateLife"];
  [coder encodeBool:keyStrokesDestroyLife forKey:@"keyStrokesDestroyLife"];
}

@synthesize color;
@synthesize keyStrokesCreateLife;
@synthesize keyStrokesDestroyLife;


- (NSViewController *)createViewController {
  EffectSettingsViewController *viewController =
      [[LifeSettingsViewController alloc] init];
  [viewController setEffect:self];
  return viewController;
}

- (void)draw:(KeyboardDisplayBuffer *)theBuffer
      keyMap:(KeyMap*)keyMap
      events:(NSArray *)events {
  // compute next generation
  bzero(aliveNext, sizeof(BOOL) * kNumKeys);
  for (Key key = kMinKey; key <= kMaxKey; key++) {
    int nneighbours = 0;
    for (Key *adjacentKey = adjacentKeys[key];
         *adjacentKey != -1;
         adjacentKey++) {
      nneighbours += alive[*adjacentKey] ? 1 : 0;
    }
    
    if (alive[key] && 2 <= nneighbours && nneighbours <= 3) {
      // staying alive--don't die of lonlineness nor overcrowding
      aliveNext[key] = YES;
    } else if (!alive[key] && nneighbours == 3) {
      // a cell is born
      aliveNext[key] = YES;
    }
  }

  // create or destroy life depending on key presses
  for (KeyEvent *event in events) {
    if ([event down]) {
      if (keyStrokesCreateLife) {
        aliveNext[[event key]] = YES;
      } else if (keyStrokesDestroyLife) {
        aliveNext[[event key]] = NO;
      }
    }
  }
  
  // if nothing changed last cycle, recreate life
  
  BOOL sameAsLastTime = YES;
  
  for (Key key = kMinKey; key <= kMaxKey && sameAsLastTime; key++) {
    sameAsLastTime &= (alive[key] == aliveNext[key]);
  }
  
  if (sameAsLastTime) {
    for (Key key = kMinKey; key <= kMaxKey; key++) {
      aliveNext[key] = random() % 3;
    }  
  }
  
  // paint the buffer
  CGColorRef liveColor = CGColorCreateFromNSColor(color);
  CGColorRef deadColor = CGColorCreateGenericRGB(0.0f, 0.0f, 0.0f, 0.0f);
  
  for (Key key = kMinKey; key <= kMaxKey; key++) {
    [buffer setKey:key color:(aliveNext[key] ? liveColor : deadColor)];
  }
  
  CGColorRelease(liveColor);
  CGColorRelease(deadColor);
  
  BOOL *tmp = alive;
  alive = aliveNext;
  aliveNext = tmp;
  
  [theBuffer paintBuffer:buffer];
}

@end

@implementation LifeSettingsViewController

- (id)init {
  return [super initWithNibName:@"LifeSettings" bundle:nil];
}
@end
