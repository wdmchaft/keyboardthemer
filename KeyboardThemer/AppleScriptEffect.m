/*
 * Copyright 2009 Dominic Cooney.
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

#import "AppleScriptEffect.h"

#import "ScriptingKey.h"


@implementation AppleScriptEffect

+ (NSDictionary *)undoProperties {
  return [NSDictionary dictionary];
}

@synthesize keys;

- (id)init {
  self = [super init];
  if (self) {
    [self setName:@"AppleScript"];
    keys = [[ScriptingKey keys] retain];
    buffer = [[KeyboardDisplayBuffer alloc] init];
  }
  return self;
}

- (void)dealloc {
  [keys release];
  [buffer release];
  [super dealloc];
}

- (id)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    keys = [[ScriptingKey keys] retain];
    buffer = [[KeyboardDisplayBuffer alloc] init];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
}

- (void)draw:(KeyboardDisplayBuffer *)displayBuffer
      keyMap:(KeyMap*)keyMap
      events:(NSArray *)events {
  for (ScriptingKey *scriptingKey in keys) {
    [scriptingKey paint:buffer];
  }
  [displayBuffer paintBuffer:buffer];
}

- (NSViewController *)createViewController {
  EffectSettingsViewController *viewController =
      [[NoSettingsViewController alloc] init];
  [viewController setEffect:self];
  return viewController;  
}

@end