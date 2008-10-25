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

#import "ScriptingKey.h"

#import "Effect.h"


@implementation ScriptingKey

@synthesize name;
@synthesize color;
@synthesize opacity;

+ (NSArray*)keys {
  NSMutableArray *array = [NSMutableArray arrayWithCapacity:kNumKeys];
  KeyMap *keyMap = [[[KeyMap alloc] init] autorelease];
  
  for (Key key = kMinKey; key <= kMaxKey; key++) {
    ScriptingKey *scriptingKey =
        [[ScriptingKey alloc] initWithKey:key named:[keyMap nameForKey:key]];
    [scriptingKey autorelease];
    [array addObject:scriptingKey];
  }
  
  return [NSArray arrayWithArray:array];
}

- (id)initWithKey:(Key)theKey named:(NSString*)theName {
  self = [super init];
  if (self) {
    key = theKey;
    name = [theName retain];
    [self setColor:
        [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.0]];
    [self setOpacity:[NSNumber numberWithDouble:0.0f]];
  }
  return self;
}

- (void)dealloc {
  [name release];
  [color release];
  [super dealloc];
}

- (NSNumber *)opacity {
  return [NSNumber numberWithDouble:[color alphaComponent]];
}

- (void) setOpacity:(NSNumber*)opacity {
  NSColor *newColor = [NSColor colorWithCalibratedRed:[color redComponent]
                                                green:[color greenComponent]
                                                 blue:[color blueComponent]
                                                alpha:[opacity doubleValue]];
  [self setColor:newColor];
}

- (void)paint:(KeyboardDisplayBuffer*)buffer {
  CGColorRef cgColor = CGColorCreateFromNSColor(color);
  [buffer setKey:key color:cgColor];
  CGColorRelease(cgColor);
}


@end
