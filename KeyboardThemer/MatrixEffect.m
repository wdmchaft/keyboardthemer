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

#import "MatrixEffect.h"


const int width = 18;
const int height = 5;


@interface MatrixSpark : NSObject {
  CGFloat power;
  int x;
  int y;
  int t;
}

- (BOOL)draw:(CGFloat *)buffer;

@end

@implementation MatrixSpark

- (id)init {
  self = [super init];
  if (self) {
    power = 0.25f + (random() % 50) / 100.0f;
    x = random() % 18;
    y = 0;
  }
  return self;
}

- (BOOL)draw:(CGFloat *)buffer {
  // set the trail of the spark to green
  if (y > 0) {
    buffer[4 * ((y - 1) * width + x)] = 0.0f;
    buffer[4 * ((y - 1) * width + x) + 1] = 1.0f;
    buffer[4 * ((y - 1) * width + x) + 2] = 0.0f;
    buffer[4 * ((y - 1) * width + x) + 3] = power;
  }
  
  // draw the spark
  if (y < height) {
    buffer[4 * (y * width + x)] = 0.5f;
    buffer[4 * (y * width + x) + 1] = 1.0f;
    buffer[4 * (y * width + x) + 2] = 0.5f;
    buffer[4 * (y * width + x) + 3] = 0.5f;
  }
  
  // move the spark
  y++;
  
  // keep drawing this spark if it is on the keyboard now
  return y <= height;
}

@end


@interface MatrixEffect (Private)

- (void)initMembers;

@end


@implementation MatrixEffect

+ (NSDictionary *)undoProperties {
  return [NSDictionary dictionary];
}

- (id)init {
  self = [super init];
  if (self) {
    [self setName:@"Matrix"];
    [self initMembers];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self initMembers];
  }
  return self;
}

- (void)initMembers {
  buffer = (CGFloat *)calloc(4 * 18 * 5, sizeof(CGFloat));
  sparks = [[NSMutableArray arrayWithCapacity:36] retain];
}

- (void)dealloc {
  free(buffer);
  [sparks release];
  [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
}

- (NSViewController *)createViewController {
  EffectSettingsViewController *viewController =
      [[NoSettingsViewController alloc] init];
  [viewController setEffect:self];
  return viewController;  
}

- (void)draw:(KeyboardDisplayBuffer *)displayBuffer
      keyMap:(KeyMap*)keyMap
      events:(NSArray *)events {
  // fade out the existing sparks
  for (int i = 0; i < width * height; i++) {
    buffer[4 * i + 3] *= 0.9f;
  }
  
  // refresh the live sparks
  for (MatrixSpark *spark in [[sparks copy] autorelease]) {
    if (![spark draw:buffer]) {
      [sparks removeObject:spark]; 
    }
  }
  
  if (random() % 3 == 0) {
    // create new sparks
    for (int i = random() % 4; i; i--) {
      [sparks addObject:[[MatrixSpark alloc] init]];
    }
  }
  
  [displayBuffer paintBitmap:buffer];
}

@end