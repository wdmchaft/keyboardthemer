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

// Key press and release events, for effects which react to key presses and
// releases. Key events are sourced from Keyboard.m, but are only available if
// access for assistive devices is enabled in Universal Access.

#import <Cocoa/Cocoa.h>

#import "Key.h"


@interface KeyEvent : NSObject {
  Key key;
  BOOL down;
}

@property Key key;
@property BOOL down;

- (id)initWithKey:(Key)key isDown:(BOOL)down;

@end
