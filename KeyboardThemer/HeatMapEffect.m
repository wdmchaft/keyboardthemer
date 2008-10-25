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

#import "HeatMapEffect.h"


@implementation HeatMapEffect

+ (NSDictionary *)undoProperties {
  return [NSDictionary dictionaryWithObjectsAndKeys:
          @"Color", @"color",
          nil];
}

@synthesize color;

- (id)init {
  self = [super init];
  if (self) {
    [self setName:@"Heat Map"];
    [self setColor:[NSColor whiteColor]];
    buffer = [[KeyboardDisplayBuffer alloc] init];
  }
  return self;
}

- (void)dealloc {
  [buffer release];
  [super dealloc];
}

- (id)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self setColor:[coder decodeObjectForKey:@"color"]];
    buffer = [[KeyboardDisplayBuffer alloc] init];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:color forKey:@"color"];
}

- (NSViewController *)createViewController {
  EffectSettingsViewController *viewController =
      [[HeatMapSettingsViewController alloc] init];
  [viewController setEffect:self];
  return viewController;
}

- (void)draw:(KeyboardDisplayBuffer *)displayBuffer
      keyMap:(KeyMap*)keyMap
      events:(NSArray *)events {
  for (Key key = kMinKey; key <= kMaxKey; key++) {
    CGFloat r, g, b, a;
    [buffer colorComponentsForKey:key r:&r g:&g b:&b a:&a];
    a *= 0.8f;
    CGColorRef fadedColor = CGColorCreateGenericRGB(r, g, b, a);
    [buffer setKey:key color:fadedColor];
    CGColorRelease(fadedColor);
  }
  
  CGColorRef hotColor = CGColorCreateFromNSColor(color);
  
  for (KeyEvent *event in events) {
    [buffer setKey:[event key] color:hotColor];
  }
  
  [displayBuffer paintBuffer:buffer];
  
  CGColorRelease(hotColor);
}

@end


@implementation HeatMapSettingsViewController

- (id)init {
  return [super initWithNibName:@"HeatMapSettings" bundle:nil];
}

@end