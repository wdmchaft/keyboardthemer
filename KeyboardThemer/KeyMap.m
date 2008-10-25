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

#import "KeyMap.h"


typedef struct {
  // a textual description of the key, for debugging
  NSString *name;
  
  // the keyboard scan code of the key
  int scanCode;
  
  // the offset of the key's red component in the linearized representation
  int offset;
} KeyMapEntry;


KeyMapEntry keyMap[] = {
  // first row
  { @"~", 0x32, 0x00 },
  { @"1", 0x12, 0x03 },
  { @"2", 0x13, 0x06 },
  { @"3", 0x14, 0x09 },
  { @"4", 0x15, 0x0c },
  { @"5", 0x17, 0x0f },
  { @"6", 0x16, 0x12 },
  { @"7", 0x1a, 0x15 },
  { @"8", 0x1c, 0x18 },
  { @"9", 0x19, 0x1b },
  { @"0", 0x1d, 0x1e },
  { @"-", 0x1b, 0x21 },
  { @"=", 0x18, 0x24 },
  { @"Backspace", 0x33, 0x27 },
  // second row
  { @"Tab", 0x30, 0x2a },
  { @"Q", 0x0c, 0x2d },
  { @"W", 0x0d, 0x30 },
  { @"E", 0x0e, 0x33 },
  { @"R", 0x0f, 0x36 },
  { @"T", 0x11, 0x39 },
  { @"Y", 0x10, 0x3c },
  { @"U", 0x20, 0x3f },
  { @"I", 0x22, 0x42 },
  { @"O", 0x1f, 0x45 },
  { @"P", 0x23, 0x48 },
  { @"[", 0x21, 0x4b },
  { @"]", 0x1e, 0x4e },
  { @"\\", 0x2a, 0x51 },
  // third row
  { @"CapsLock", 0x39, 0x54 },
  { @"A", 0x00, 0x57 },
  { @"S", 0x01, 0x5a },
  { @"D", 0x02, 0x5d },
  { @"F", 0x03, 0x60 },
  { @"G", 0x05, 0x63 },
  { @"H", 0x04, 0x66 },
  { @"J", 0x26, 0x69 },
  { @"K", 0x28, 0x6c },
  { @"L", 0x25, 0x6f },
  { @";", 0x29, 0x72 },
  { @"'", 0x27, 0x75 },
  // Enter has two keys above, but none to the right
  { @"Enter", 0x24, 0x78 },
  // fourth row
  { @"LeftShift", 0x38, 0x7b },
  { @"Z", 0x06, 0x7e },
  { @"X", 0x07, 0x81 },
  { @"C", 0x08, 0x84 },
  { @"V", 0x09, 0x87 },
  { @"B", 0x0b, 0x8a },
  { @"N", 0x2d, 0x8d },
  { @"M", 0x2e, 0x90 },
  { @",", 0x2b, 0x93 },
  { @".", 0x2f, 0x96 },
  { @"/", 0x2c, 0x99 },
  { @"RightShift", 0x3c, 0x9c },
  // fifth row
  { @"LeftCtrl", 0x3b, 0x9f },
  { @"LeftVendor", 0x37, 0xa2 },
  { @"LeftAlt", 0x3a, 0xa5 },
  { @"RightAlt", 0x3d, 0xae },
  { @"RightVendor", 0x36, 0xb4 },
  { @"RightMenu", 0x6e, 0xb7 },
  { @"RightCtrl", 0x3e, 0xa8 },
  // top right control pad
  { @"Home", 0x73, 0xc9 },
  { @"PgUp", 0x74, 0xcc },
  { @"Delete", 0x75, 0xcf },
  { @"End", 0x77, 0xd2 },
  { @"PgDn", 0x79, 0xd5 },
  // arrow keys
  { @"Left", 0x7b, 0xdb },
  { @"Right", 0x7c, 0xe1 },
  { @"Down", 0x7d, 0xde },
  { @"Up", 0x7e, 0xd8 },
  NULL
};


@implementation KeyMap
- (BOOL)keyForScanCode:(int)scanCode key:(Key*)key {
  // TODO: construct an O(1) lookup for this
  for (int i = kMinKey; i <= kMaxKey; i++) {
    if (keyMap[i].scanCode == scanCode) {
      *key = (Key)i;
      return YES;
    }
  }
  return NO;
}

- (int)offsetForKey:(Key)key {
  assert(kMinKey <= key && key <= kMaxKey);
  return keyMap[key].offset;
}

- (Key)keyForOffset:(int)offset {
  // TODO: construct an O(1) lookup for this
  for (int i = kMinKey; i <= kMaxKey; i++) {
    if (keyMap[i].offset == offset) {
      return i;
    }
  }
  @throw @"key not found for offset";
}

- (NSString*)nameForKey:(Key)key {
  return keyMap[key].name;
}

@end
