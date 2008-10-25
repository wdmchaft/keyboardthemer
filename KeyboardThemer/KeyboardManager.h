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

// Detects when a Luxeed deTA100 keyboard is inserted or removed.

#import <Cocoa/Cocoa.h>

#import "Keyboard.h"


@interface KeyboardManager : NSObject {
  Keyboard *keyboard;
@private
  UInt32 keyboardLocation;
  NSMapTable *keyboards;
}

@property (retain) Keyboard *keyboard;

+ (KeyboardManager *)sharedInstance;
+ (void)releaseSharedInstance;
- (IOReturn)start;
- (IOReturn)stop;

@end


