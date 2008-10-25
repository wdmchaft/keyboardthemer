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

// The keys on the keyboard that can be illuminated.

typedef enum {
  // first row
  kKeyTilde,
  kKey1,
  kKey2,
  kKey3,
  kKey4,
  kKey5,
  kKey6,
  kKey7,
  kKey8,
  kKey9,
  kKey0,
  kKeyMinus,
  kKeyEquals,
  kKeyBackspace,
  
  // second row
  kKeyTab,
  kKeyQ,
  kKeyW,
  kKeyE,
  kKeyR,
  kKeyT,
  kKeyY,
  kKeyU,
  kKeyI,
  kKeyO,
  kKeyP,
  kKeyLeftSquare,
  kKeyRightSquare,
  kKeyBackslash,
  
  // third row
  kKeyCapsLock,
  kKeyA,
  kKeyS,
  kKeyD,
  kKeyF,
  kKeyG,
  kKeyH,
  kKeyJ,
  kKeyK,
  kKeyL,
  kKeySemicolon,
  kKeySingleQuote,
  kKeyEnter,
  
  // fourth row
  kKeyLeftShift,
  kKeyZ,
  kKeyX,
  kKeyC,
  kKeyV,
  kKeyB,
  kKeyN,
  kKeyM,
  kKeyComma,
  kKeyPeriod,
  kKeyForwardSlash,
  kKeyRightShift,
  
  // fifth row
  kKeyLeftCtrl,
  kKeyLeftVendor,
  kKeyLeftAlt,
  kKeyRightAlt,
  kKeyRightVendor,
  kKeyRightMenu,
  kKeyRightCtrl,
  
  // arrows and misc.
  kKeyHome,
  kKeyPgUp,
  kKeyDelete,
  kKeyEnd,
  kKeyPgDn,
  kKeyLeft,
  kKeyRight,
  kKeyDown,
  kKeyUp
} Key;

// the first key in the key enumeration
static const int kMinKey = kKeyTilde;

// the last key in the key enumeration
static const int kMaxKey = kKeyUp;

// the number of keys in the key enumeration
static const int kNumKeys = kKeyUp + 1;
