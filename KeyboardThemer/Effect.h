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

// The base type of effects which render keys.

#import <Cocoa/Cocoa.h>

#import "KeyboardDisplayBuffer.h"
#import "KeyEvent.h"
#import "KeyMap.h"


CGColorRef CGColorCreateFromNSColor(NSColor *color);


@interface Effect : NSObject <NSCoding> {
  NSString* name;
  BOOL visible;
}

@property (retain) NSString* name;
@property BOOL visible;

+ (NSString *)pasteboardType;

- (void)draw:(KeyboardDisplayBuffer *)buffer
      keyMap:(KeyMap*)keyMap
      events:(NSArray *)events;

- (NSViewController *)createViewController;

@end


@interface EffectSettingsViewController : NSViewController {
  Effect* effect;
}

@property (retain) Effect* effect;

@end


@interface NoSettingsViewController : EffectSettingsViewController {
  
}

@end
