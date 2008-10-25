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

#import "LayerEffect.h"


@implementation LayerEffect

+ (NSDictionary *)undoProperties {
  NSLog(@"LayerEffect undoProperties");
  return [NSDictionary dictionary];
}

- (id)init {
  self = [super init];
  if (self) {
    arrangedEffects = [[[NSMutableArray alloc] init] retain];
  }
  return self;
}

- (void)dealloc {
  [arrangedEffects release];
  [super dealloc];
}

- (id)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    arrangedEffects = [[coder decodeObjectForKey:@"arrangedEffects"] retain];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:arrangedEffects forKey:@"arrangedEffects"];
}

@synthesize arrangedEffects;

- (void)draw:(KeyboardDisplayBuffer *)buffer
      keyMap:(KeyMap*)keyMap
      events:(NSArray *)events {
  for (int i = [arrangedEffects count] - 1; i >= 0; i--) {
    Effect *effect = (Effect *)[arrangedEffects objectAtIndex:i];
    if ([effect visible]) {
      [effect draw:buffer keyMap:keyMap events:events];
    }
  }
}

@end
